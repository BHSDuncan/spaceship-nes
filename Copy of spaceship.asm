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
  buttons1:   dsb 1  ; player 1 gamepad buttons, one bit per button
  playerX: dsb 1
  playerY: dsb 1
  playerShootSalvo: dsb 1
  playerShootDelay: dsb 1
  bullets: dsb 32 ; 2 bytes per bullet to store (x,y)
  bulletCount: dsb 1
  bulletIndex: dsb 1  
  
  gamestate: dsb 1  ; db 1 means reserve one byte of space
ENDE

;; constants
STATETITLE     = $00  
STATEPLAYING   = $01  
STATEGAMEOVER  = $02  

PLAYER_SPRITE = $0200
BULLET_SPRITE = $0218

BULLET_SPEED = $08
MAX_PLAYER_BULLETS = $10
MAX_SALVO = $04
SHOOT_DELAY = $08
MAX_PLAYER_BULLETS_INDEX = $20

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
  LDA #$00
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
  CPX #$1C              
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down  
  
LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$1C              ; Compare X to hex $18, decimal 24
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 16, keep going down

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

InitVars:
  LDX #$00
  STX bulletCount 
  STX playerShootDelay
  
  LDA #STATEPLAYING
  STA gamestate
    
  LDX #$80
  STX playerX
  
  LDX #$D5
  STX playerY
  
  LDX #MAX_SALVO
  STX playerShootSalvo
  
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

CheckNoFire:
  LDA buttons1
  AND #%10000000
  BNE MoveShipLeft
  
  ; if the buttons have been let go, then reset the salvo
  LDA #MAX_SALVO
  STA playerShootSalvo
  
  LDA #$00
  STA playerShootDelay

MoveShipLeft:
  LDA buttons1
  AND #%00000010
  BEQ MoveShipLeftDone ; if this isn't the left button, then we're done
  
  LDA playerX
  SEC
  SBC #$01
  STA playerX  

MoveShipLeftDone:

MoveShipRight:
  LDA buttons1
  AND #%00000001
  BEQ MoveShipRightDone ; if this isn't the right button, then we're done

  LDA playerX
  CLC
  ADC #$01
  STA playerX  

MoveShipRightDone:  

MoveShipUp:
  LDA buttons1
  AND #%00001000
  BEQ MoveShipUpDone
  
  LDA playerY
  SEC
  SBC #$01
  STA playerY 
  
MoveShipUpDone:

MoveShipDown:
  LDA buttons1
  AND #%00000100
  BEQ MoveShipDownDone
  
  LDA playerY
  CLC
  ADC #$01
  STA playerY
  
MoveShipDownDone:

; fire
CheckFire:
  LDA playerShootDelay
  BEQ CheckA
  
  JMP CheckFireDone
  
  CheckA:
    LDA buttons1
    AND #%10000000
    BEQ CheckFireDone
  
    JSR DoShoot
    
CheckFireDone:

JSR UpdatePlayerBullets

AllDone:

UpdateSprites:
  ; vert
  LDA playerY 
  
  STA PLAYER_SPRITE
  STA PLAYER_SPRITE+$4
  CLC
  ADC #$08
  STA PLAYER_SPRITE+$8
  STA PLAYER_SPRITE+$C
  CLC
  ADC #$08
  STA PLAYER_SPRITE+$10
  STA PLAYER_SPRITE+$14
    
  ; horiz
  LDA playerX
  
  STA PLAYER_SPRITE+$3
  STA PLAYER_SPRITE+$B     
  STA PLAYER_SPRITE+$13
  CLC
  ADC #$08
  STA PLAYER_SPRITE+$7
  STA PLAYER_SPRITE+$F
  STA PLAYER_SPRITE+$17
  
  JSR DisplayPlayerBullets
  
  RTS

UpdatePlayerBullets:
  LDX #$00  ; current index into bullets
  LDY #$00  ; updated index into bullets

  LDA bulletCount
  CMP #$00
  BEQ UpdatePlayerBulletsDone
  
  ; we need to ensure we remove any 'dead' bullets in between 'live' ones, and also update their positions
  UpdatePlayerBulletsLoop:
  
    LDA bullets, x
   
    SEC
    SBC #BULLET_SPEED
    BCC DestroyBullet ; if we've gone off the top of the screen, this bullet is history

    ; move the bullet forward
    STA bullets, y
    LDA bullets+$1, x
    STA bullets+$1, y
    
    INY
    INY
    
    UpdatePlayerBulletsLoopContinue:
      CPX bulletIndex
      INX
      INX
      BCC UpdatePlayerBulletsLoop ; if the CPX instruction above doesn't set the carry flag, i.e. X < bulletIndex, then continue
    
    
  ; need to go over the array again since the old values still remain, i.e. deal with the new redundancies
  
  ; if no more bullets, well, we're done
  CPY #$00
  BEQ NoMoreBullets
  
  DEY
  DEY
  STY bulletIndex
  
  INY
  INY

  RemoveRedundantBullets:
    LDA #$00
    STA bullets, y
    STA bullets+$1, y
    
    DEX
    CPX bulletIndex
    BNE RemoveRedundantBullets
        
  UpdatePlayerBulletsDone:
    RTS

  DestroyBullet:
    DEC bulletCount
    JMP UpdatePlayerBulletsLoopContinue

  NoMoreBullets:
    LDA #$00
    STA bulletIndex
    JMP UpdatePlayerBulletsDone


DisplayPlayerBullets:

  ; if we have an empty bullet count, we may need to remove the first bullet there, but have to do a bit of trickery since underflow prevents a normal lookup
  LDA bulletCount
  CMP #$00
  BEQ RemoveFirstBullet
  
  LDX #$FE ; off-screen bullet index
  LDY #$00 ; on-screen bullet sprite index
  
  DisplayPlayerBulletsLoop:
    INX
    INX  ; gets us to 0, i.e. first index of bullets
    
    ; vert
    LDA bullets, x
    STA BULLET_SPRITE, y
    
    ; tile
    LDA #$06
    STA BULLET_SPRITE+$1, y
    
    ; attribs
    STA BULLET_SPRITE+$2, y  ; since palette is same as tile here

    ; horiz
    LDA bullets+$1, x
    STA BULLET_SPRITE+$3, y
    
    ; advance y register to next sprite, 4 bytes ahead
    INY
    INY
    INY
    INY
    
    CPX bulletIndex
    BNE DisplayPlayerBulletsLoop
  
  ; need to check for bullets to remove that have expired/gone off the screen
  RemoveExpiredBullets:
    ; TODO: Look at why commenting this out doesn't produce as many "stuck" bullets on the screen after firing a lot.
    ; don't go past the max bullets we can hold
    ;CPY #MAX_PLAYER_BULLETS_INDEX
    ;BEQ DisplayPlayerBulletsDone
    
    ; if this bullet is non-existent, then we're done (we assume that we've cleaned up the array so that any non-existent sprites aren't in the middle of valid ones)
    LDA BULLET_SPRITE, y
    CMP #$FE
    BEQ DisplayPlayerBulletsDone
    
    LDA #$FE
    STA BULLET_SPRITE, y
    
    INY
    JMP RemoveExpiredBullets    
  
  RemoveFirstBullet:
    LDX #$FE  ; value to clear out first spirte
    STX BULLET_SPRITE
    STX BULLET_SPRITE+$1
    STX BULLET_SPRITE+$2
    STX BULLET_SPRITE+$3
    INX
    INX
    STX bullets   ; zero these out; $FE + $02 = $00
    STX bullets+1
    
  DisplayPlayerBulletsDone:
    RTS

 
DoShoot:
  LDA bulletCount
  CMP #MAX_PLAYER_BULLETS
  BEQ DoShootDelay ; do something else, actually, since this is the limit of the # of bullets we track

  LDA playerShootSalvo
  BEQ DoShootDelay    ; if we hit zero shots left in the salvo, cool down
  
  DEC playerShootSalvo

  LDA bulletCount
    
  INC bulletCount
  CLC
  ADC bulletCount
  
  TAX ; need bulletCount * 2 to store X info, and use this to get the index
  DEX ; decrement for 0-based counter

  STX bulletIndex
  
  LDA playerY
  STA bullets, x
  
  LDA playerX
  CLC
  ADC #$04
  STA bullets+$1, x 
    
  JMP DoShootDone
   
  DoShootDelay:
    LDA #$01
    STA playerShootDelay
   
  DoShootDone:
  	RTS
 
ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  
  RTS
  
;;;;;;;;;;;

  .org $E000
palette:
  .incbin "spaceship.dat"

sprites:
     ;vert tile attr horiz
  .db $D5, $00, $00, $80   ;sprite 0
  .db $D5, $01, $00, $88   ;sprite 1
  .db $DD, $02, $00, $80   ;sprite 2
  .db $DD, $03, $00, $88   ;sprite 3
  .db $E5, $04, $00, $80   ;sprite 4
  .db $E5, $05, $00, $88   ;sprite 5
  .db $00, $06, $06, $00   ;sprite 6





  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  BASE $0000
  .incbin "spaceship.chr" 