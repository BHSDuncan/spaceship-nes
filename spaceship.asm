PRG_COUNT = 2 ;1 = 16KB, 2 = 32KB
MIRRORING = %0011 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

   .db "NES", $1a ;identification of the iNES header
   .db PRG_COUNT ;number of 16KB PRG-ROM pages
   .db $01 ;number of 8KB CHR-ROM pages
   ;.db $30|MIRRORING ;mapper 3 and mirroring
   .db MIRRORING ;mapper 0 and mirroring
   .dsb 9, $00 ;clear the remaining bytes

;;;;;;;;;;;;;;;;;;

;; variables
ENUM $0001  ;;start variables at ram location 1; at 0, setting #$02 to certain variables seems to mess things up; dig into this later.
  gamestate: dsb 1  ; db 1 means reserve one byte of space
  pointerLow: .dsb 1
  pointerHigh: .dsb 1
  scroll: .dsb 1
  scrollFlip: .dsb 1
  nametable: .dsb 1
  sleeping: .dsb 1
  
  displayListReady: .dsb 1
  displayListIndex: .dsb 1
  displayListStrLen: .dsb 1
  
  scoreSpriteAddr: 
  	scoreSpriteAddrL: .dsb 1
  	scoreSpriteAddrH: .dsb 1
    
  needDMA: .dsb 1
  needDraw: .dsb 1
  
  ; used as a 16-bit register comprised of a high-byte and low-byte
  AX:
  AL: .dsb 1
  AH: .dsb 1
 
ENDE

ENUM $0300 ; try using this for "BSS"

  displayList: .dsb 256

ENDE

;; constants
STATETITLE     = $00  
STATEPLAYING   = $01  
STATEGAMEOVER  = $02  

DRAW_DELAY = $03
SCROLL_START = $EF

NUM_SCORE_DIGITS = 6

SCORE_START_SPRITE = $02DC
SCORE_START_HORIZ = $08

BLINK_FRAME_COUNT = $20
;;;;;;;;;;;;;;;;;;

; borrowed this idea from "furrykef" on GitHub
MACRO DlBegin
  LDA #$00
  STA displayListReady 
  LDX displayListIndex
ENDM

MACRO DlAddA
  STA displayList, x
  INX
ENDM

MACRO DlAddString string
  LDY #$00
  
  DlAddStringLoop:
	  LDA string, y
	  DlAddA
	  
	  INY
	  
	  CPY displayListStrLen
	  BNE DlAddStringLoop
  
ENDM 

MACRO DlEnd
  LDA #$01
  STA displayListReady
  STX displayListIndex
  
ENDM

;;;;;;;;;;;;;;;;;;

  .base $10000-(PRG_COUNT*$4000)
  
vblankwait:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait
  RTS
   
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

  JSR vblankwait
  
clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
  
  ; need this in case the system (emulator?) is reset in order to clear out the sprites
  LDA #$01
  STA needDMA
  
  JSR vblankwait
   
  ; load in title bg stuff
  JSR DoTitleBankSwap
  
  LDA #$01
  STA needDraw
    
;;;;;;;;;;;;;;;;;;;;


JSR InitSineTable
JSR InitCosineTable

InitVars:
  LDA #STATETITLE
  STA gamestate
  
  LDA #$00
  STA seed  
  STA nametable  
  STA displayListIndex
  STA displayListReady
  
  LDA #SCROLL_START
  STA scroll
  
  LDA #DRAW_DELAY
  STA scrollFlip
  
  ; going to borrow some vars from other areas to help w blink
  LDA #BLINK_FRAME_COUNT
  STA frameCounter
  
  LDA #$50
  STA tempBVar
  
;;;;;;;;;;;;;;;;;;;
; Separate the logic from the drawing: Do the logic here, so we don't overload the NMI and risk not getting all the drawing done for vBlank.
;
  
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011000   ; enable sprites, enable background, no clipping on left side
  STA $2001  
  
  JSR sound_init

  LDA #MAIN_SONG_IDX
  JSR sound_load

DoFrame:
  JSR ReadController1  ;;get the current button data for player 1
  ;JSR ReadController2  ;;get the current button data for player 2
  
  LDA gamestate
  CMP #STATEPLAYING
  BNE @stateTitle
  
  DEC scrollFlip
  
  JMP @gameEngine  
  
  @stateTitle:
  CMP scrollFlip
  
  @gameEngine:
  BNE GameEngine   
  
  LDA #DRAW_DELAY
  STA scrollFlip
    
  LDA #$01
  STA needDraw  
  
  GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BEQ EngineTitle    ;;game is displaying title screen
    
  ;LDA gamestate
  ;CMP #STATEGAMEOVER
  ;BEQ EngineGameOver  ;;game is displaying ending screen
  
    LDA gamestate
    CMP #STATEPLAYING
    BEQ EnginePlaying   ;;game is playing
  
  GameEngineDone: 
  
  ;LDA #$01
  ;STA needDMA  

  JSR WaitFrame

  JMP DoFrame
  
;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Try to do the NMI a bit differently and more separated/organized: This waits for vBlank and returns when the NMI handler is finished.
;
WaitFrame:
  INC sleeping
  
  WaitFrameLoop:
    LDA sleeping
    BNE WaitFrameLoop
    
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;

DoBlink:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23EA address
  LDA #$EA
  STA $2006             ; write the low byte of $23EA address
  LDX #$00              
  @blinkAttrLoop:
  LDA tempBVar
  STA $2007             ; write to PPU
  INX
  CPX #$04
  BNE @blinkAttrLoop
  
  LDA tempBVar
  BEQ @setBlinkInvisible
  
  LDA #$00
  
  JMP @doBlinkDone
  
  @setBlinkInvisible:
  LDA #$50
  
  @doBlinkDone:
  STA tempBVar
  
  ; would really like to know why I have to do this here when I have something similar below
  ;LDA #$01
  ;STA needDraw
  LDA #$00
  STA $2005
  STA $2005
  
  RTS
;;;;;;;;;;;;;;;;;;;;;;
EngineTitle:
  DEC frameCounter
  BNE @skipBlink

  JSR DoBlink

  LDA #BLINK_FRAME_COUNT
  STA frameCounter
  
  @skipBlink:
  JSR HandlePlayerInput
  
  JMP GameEngineDone

EnginePlaying:

  JSR HandlePlayerInput
  JSR DoPlayerBehaviour
  JSR DoEnemyBehaviour
  JSR DrawScore
  
  JSR UpdateSprites
  
  JMP GameEngineDone

UpdateSprites:
  JSR UpdatePlayerSprites
  JSR UpdateEnemySprites
 
  LDA displayListReady
  BEQ SkipDlFlush
    
  JSR FlushDl  
 
  SkipDlFlush:
  
  RTS

;;;;;;;;;;;

NMI:
  ; backup the registers first
  PHA
  TXA
  PHA
  TYA
  PHA

  BIT $2002

  DMACheck:
  
  LDA needDMA
  BEQ DrawCheck
  
  LDA #$00
  STA needDMA

  STA $2003       
  LDA #$02
  STA $4014       ; sprite DMA from $0200

DrawCheck:

LDA needDraw
BEQ RestoreRegisters

  DEC scroll       ; subtract one from our scroll variable each frame
NTSwapCheck:
  LDA scroll       ; check if the scroll just wrapped from 255 to 0
  CMP #$FF
  BNE NTSwapCheckDone
  
  LDA #SCROLL_START
  STA scroll
  
NTSwap:
  LDA nametable    ; load current nametable number (0 or 2)
  EOR #$02         ; exclusive OR of bit 0 will flip that bit
  STA nametable    ; so if nametable was 0, now 2
                   ;    if nametable was 2, now 0
NTSwapCheckDone:

  LDA #$00
  STA $2006        ; clean up PPU address registers
  STA $2006
  
  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA gamestate
  CMP #STATETITLE
  BNE @setupPlaying  

  ; have to explicitly state no scrolling while in this mode
  LDA #$00
  STA $2005
  STA $2005   

  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  
  LDA #%00011000   ; enable sprites, enable background, clipping on left side
  STA $2001
  
  JMP @resetDraw
  
  @setupPlaying:

  LDA #$00
  STA $2005        ; write the horizontal scroll count register

  LDA scroll
  STA $2005  
  
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 0
  ORA nametable    ; select correct nametable for bit 0
  STA $2000
  
  LDA #%00011000   ; enable sprites, enable background, clipping on left side
  STA $2001

  @resetDraw
  LDA #$00
  STA needDraw
    
  RestoreRegisters:
  
  JSR sound_play_frame
  
  LDA #$00
  STA sleeping

  ; restore registers
  PLA
  TAY
  PLA
  TAX
  PLA

  RTI             ; return from interrupt

;;;;;;;;;;;;;;;;;;;;;;;;;

DrawScore:

  DlBegin
  
  LDA #NUM_SCORE_DIGITS
  STA displayListStrLen  
  DlAddA
  
  LDA #<SCORE_START_SPRITE 
  DlAddA
  
  LDA #>SCORE_START_SPRITE
  DlAddA

  DlAddString playerScore
  
  DlEnd

  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushDl:

  LDX #$00
  
  LDA #SCORE_START_HORIZ
  STA tempBVar
  
  FlushDlLoop:
  
    CPX displayListIndex
    BEQ FlushDlEnd
    
    LDY displayList, x ; chunk size
    INX
    
    LDA displayList, x ; starting sprite address (low byte)
    STA scoreSpriteAddrL
    INX

    LDA displayList, x ; starting sprite address (high byte)
    STA scoreSpriteAddrH
    INX
        
    FlushDlCopyLoop:
      TYA
      PHA
    
      LDY #$00
      
      ; draw the text sprite

	  ; vert 
	  LDA #$0A
	  STA (scoreSpriteAddr), y
	  
	  INY
	  
	  ; tile
      LDA displayList, x
      CLC
      ADC #$30
      STA (scoreSpriteAddr), y
	  
	  INY
	  
	  ; attr
	  LDA #$00
	  STA (scoreSpriteAddr), y
	  
	  INY
	  
	  ; horiz
	  LDA tempBVar
	  STA (scoreSpriteAddr), y

	  CLC
	  ADC #$08
	  STA tempBVar
	  
	  ; increment the sprite location/info	  
	  LDA scoreSpriteAddrL
	  CLC
	  ADC #$04
	  STA scoreSpriteAddrL
	  
	  ; check for carry
      LDA scoreSpriteAddrH
      ADC #$00
      STA scoreSpriteAddrH
      	  	  
	  ; restore y
	  PLA
	  TAY
	  
	  INX
	  
	  DEY
	  
	  BNE FlushDlCopyLoop
	  BEQ FlushDlLoop
	  
  FlushDlEnd:
  	LDA #$00
  	STA displayListIndex
  	STA displayListReady
  	
  	LDA #$01
  	STA needDMA
  	
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;

Bankswitch:

  TAX ;;copy A into X

  STA Bankvalues, X ;;new bank to use

  RTS


Bankvalues:

  .db $00, $01 ;bank numbers


;;;;;;;;;;;;;;;;;;;;;;;;;;

.org $E000
  
palette:
  .incbin "spaceship.dat"

bgPalette:
  .db $0f,$00,$10,$30,$0f,$01,$21,$2d,$0f,$06,$16,$26,$0f,$09,$19,$29

titlePalette:
  .incbin "title.pal"

; trying to implement unpacked BCD representation since the NES 6502 doesn't support BCD natively
Points100: .db 0,0,0,1,0,0

bgdat:
  .incbin "space.nam"
  
bgattrs:
  .incbin "spaceAttr.bin"

titleDat:
  .incbin "title.nam"
  
titleAttrs:
  .incbin "title.bin"

  .include "math.asm"
  .include "enemies.asm"
  .include "player.asm"

  ; this prevents the "swap" includes from executing when being included
  LDA #$01  

  .include "title_bank_swap.asm"
  .include "level_bank_swap.asm"

	.include "sound/sound_engine.asm"
	.include "sound/sound_opcodes.asm"
	.include "sound/note_table.asm" ;period lookup table for notes
    .include "sound/volume_envelopes.asm"
    .include "sound/sound_headers.asm"
	.include "sound/main_song.asm"
	.include "sound/explosion_sound.asm"
	.include "sound/bullet_sound.asm"
	.include "sound/enemy_bullet_sound.asm"
	

.org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  ;BASE $0000 
  ;.incbin "title.chr"
  ;PAD $2000
  
  BASE $0000
  .incbin "spaceship.chr"
  ;PAD $2000