PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

   .db "NES", $1a ;identification of the iNES header
   .db PRG_COUNT ;number of 16KB PRG-ROM pages
   .db $01 ;number of 8KB CHR-ROM pages
   .db $00|MIRRORING ;mapper 0 and mirroring
   .dsb 9, $00 ;clear the remaining bytes

;;;;;;;;;;;;;;;;;;

;; variables
ENUM $0001  ;;start variables at ram location 1; at 0, setting #$02 to certain variables seems to mess things up; dig into this later.
  gamestate: dsb 1  ; db 1 means reserve one byte of space
ENDE

;; constants
STATETITLE     = $00  
STATEPLAYING   = $01  
STATEGAMEOVER  = $02  

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
  
  JSR vblankwait
   
LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$10
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$10            
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down  
  
JSR InitSineTable
JSR InitCosineTable

JSR LoadPlayerSprites
JSR LoadEnemySprites

InitVars:
  LDA #STATEPLAYING
  STA gamestate
  
  JSR InitPlayerVars
  JSR InitiEnemyVars
    
Forever:
  JMP Forever     ;jump back to Forever, infinite loop, waiting for NMI
  
 
NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00010000   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
  
  JSR ReadController1  ;;get the current button data for player 1
  ;JSR ReadController2  ;;get the current button data for player 2
  
GameEngine:  
  ;LDA gamestate
  ;CMP #STATETITLE
  ;BEQ EngineTitle    ;;game is displaying title screen
    
  ;LDA gamestate
  ;CMP #STATEGAMEOVER
  ;BEQ EngineGameOver  ;;game is displaying ending screen
  
  LDA gamestate
  CMP #STATEPLAYING
  BEQ EnginePlaying   ;;game is playing
GameEngineDone: 
  
  JSR UpdateSprites  ;;set ball/paddle sprites from positions

  RTI             ; return from interrupt

;;;;;;;;;;;;;;;

EnginePlaying:

JSR HandlePlayerInput
JSR DoEnemyBehaviour

UpdateSprites:
  JSR UpdatePlayerSprites
  JSR UpdateEnemySprites
 
JSR ReadController1

;;;;;;;;;;;

  .org $E000
  
palette:
  .incbin "spaceship.dat"

  .include "math.asm"
  .include "enemies.asm"
  .include "player.asm"


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  BASE $0000
  .incbin "spaceship.chr" 