;; variables
ENUM $0011
  buttons1:   dsb 1  ; player 1 gamepad buttons, one bit per button
  playerX: dsb 1
  playerY: dsb 1
  playerShootSalvo: dsb 1
  playerShootDelay: dsb 1
  bullets: dsb 12 ; 2 bytes per bullet to store (x,y)
  bulletCount: dsb 1
  bulletIndex: dsb 1  
  engineFlickerDelay: dsb 1
  playerState: .dsb 1
  frameCounter: .dsb 1
  
  needsSpriteUpdate: .dsb 1
  
  pScoreH: .dsb 1 ; pointer to high-byte of score
  pScoreL: .dsb 1 ; pointer to low-byte of score
  playerScore: .dsb NUM_SCORE_DIGITS ; 6
  
ENDE

;; constants
PLAYER_SPRITE = $0200
BULLET_SPRITE = $021C

BULLET_SPEED = $08
MAX_PLAYER_BULLETS = $06
MAX_SALVO = $02
SHOOT_DELAY = $08
MAX_PLAYER_BULLETS_INDEX = $0C
ENGINE_FLICKER_DELAY = $06
MIN_Y_POS_BULLET = $10

STATE_PLAYER_ALIVE = #$01
STATE_PLAYER_DYING = #$02
STATE_PLAYER_DEAD = #$03

;;;;;;;;;;;;;;;

LoadPlayerSprites:
  LDX #$00              ; start at 0
LoadPlayerSpritesLoop:
  LDA playerSprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $18, decimal 24
  BNE LoadPlayerSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 16, keep going down

  ;LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  ;STA $2000

  ;LDA #%00010000   ; enable sprites
  ;STA $2001
  
  RTS
  
;;;;;;;;;;;

InitPlayerVars:
  LDA #$00
  STA bulletCount 
  STA playerShootDelay
  STA needsSpriteUpdate
  
  LDA #<playerScore
  STA pScoreL
  
  LDA #>playerScore
  STA pScoreH
  
  ; clear the score out
  LDX #NUM_SCORE_DIGITS-1
  
  ClearScoreLoop:
    STA playerScore, x
    DEX
    BPL ClearScoreLoop
  
  LDA #$80
  STA playerX
  
  LDA #$D5
  STA playerY
  
  LDA #MAX_SALVO
  STA playerShootSalvo
  
  LDA #ENGINE_FLICKER_DELAY
  STA engineFlickerDelay
  
  LDA #STATE_PLAYER_ALIVE
  STA playerState

  LDA #$FF
  STA frameCounter
    
  RTS
  
;;;;;;;;;;;;;

HandlePlayerInput:
  LDA gamestate
  CMP #STATETITLE
  BNE CheckNoFire
  
  ; start check
  LDA buttons1
  AND #%00010000
  BEQ AllDone
  
  ; really should move this code out of player-specific handling at some point
  JSR DoLevelBankSwap
  
  JSR InitPlayerVars
  JSR InitEnemyVars
  
  JSR LoadPlayerSprites
  JSR LoadEnemySprites
  
  LDA #MAIN_SONG_IDX
  JSR sound_load
  
  LDA #STATEPLAYING
  STA gamestate
  
  JMP AllDone
  
  ; PLAYING state
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
	  
	  INC needsSpriteUpdate
	  LDA playerX
	  SEC
	  SBC #$01
	  STA playerX  
	
	MoveShipLeftDone:
	
	MoveShipRight:
	  LDA buttons1
	  AND #%00000001
	  BEQ MoveShipRightDone ; if this isn't the right button, then we're done
	
	  INC needsSpriteUpdate
	  LDA playerX
	  CLC
	  ADC #$01
	  STA playerX  
	
	MoveShipRightDone:  
	
	MoveShipUp:
	  LDA buttons1
	  AND #%00001000
	  BEQ MoveShipUpDone
	  	  
	  INC needsSpriteUpdate
	  LDA playerY
	  SEC
	  SBC #$01
	  STA playerY 
	  
	MoveShipUpDone:
	
	MoveShipDown:
	  LDA buttons1
	  AND #%00000100
	  BEQ MoveShipDownDone
	  
	  INC needsSpriteUpdate
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
	
	  RTS
;;;;;;;;;;;;;;;;;

DoPlayerBehaviour:

  LDA playerState
  
  CMP #STATE_PLAYER_ALIVE
  BNE CheckPlayerStateDying
  
  JSR CheckEnemyBulletCollision
  JSR CheckEnemyCollision
  
  CheckPlayerStateDying:
  
  LDA playerState
  CMP #STATE_PLAYER_DYING
  BNE CheckPlayerStateDone

  JSR UpdateDyingPlayer
  
  CheckPlayerStateDone:
  
  RTS

;;;;;;;;;;;;;;;;;

UpdateDyingPlayer:
  LDA frameCounter
  CMP #$FF
  BNE UpdateDyingPlayerCheckCounter
  
  LDA #$00
  STA frameCounter
  
  ; use this var for delay to save space
  STA engineFlickerDelay
  
  JMP UpdateDyingPlayerDone
  
  UpdateDyingPlayerCheckCounter:
    ; if we've shown enough frames, we're done
    CMP #MAX_EXPLOSION_FRAMES
    BNE UpdateDyingPlayerDone
    
    LDA #STATE_PLAYER_DEAD
    STA playerState
  
  UpdateDyingPlayerDone:
    RTS

;;;;;;;;;;;;;;;;

CheckEnemyCollision:
  LDA enemyCount
  BEQ CheckEnemyCollisionDone
  
  LDX #$00
  
  CheckEnemyCollisionLoop:
    CLC
    
    ; check x
    LDA enemies+$5, x
    SBC playerX
    SBC #$10-1
    ADC #$10+$10-1
    BCC CheckNextEnemyCollision
    
    CLC
    
    ; check y if carry is set
    LDA enemies+$6, x
    SBC playerY
    SBC #$18-1
    ADC #$10+$18-1
    BCC CheckNextEnemyCollision
    
    ; collision!
    LDA #STATE_PLAYER_DYING
    STA playerState

	TXA
	PHA

    LDA #SOUND_EXPLOSION_IDX
    JSR sound_load 

	PLA
	TAX

    CheckNextEnemyCollision:
      JSR IncEnemyIndexX
    
      CPX enemyIndex
      BNE CheckEnemyCollisionLoop
        
    CheckEnemyCollisionDone:
  RTS
;;;;;;;;;;;;;;;;

CheckEnemyBulletCollision:
  LDA enemyBulletCount
  BEQ CheckEnemyBulletCollisionDone
    
  LDX #$00  ; enemy bullet index
  
  CheckEnemyBulletCollisionLoop:
    CLC
    
    ; check x
    LDA enemyBullets, x
    SBC playerX
    SBC #$10-1 ; player size
    ADC #$10+$10-1
    BCC CheckNextEnemyBulletCollision
    
    CLC
    
    ; check y if carry is set
    LDA enemyBullets+$1, x
    SBC playerY
    SBC #$18-1 ; player size
    ADC #$08+$18-1
    BCC CheckNextEnemyBulletCollision
    
    ; collision!
    LDA #STATE_PLAYER_DYING
    STA playerState
    
    TXA
    PHA
    
    LDA #SOUND_EXPLOSION_IDX
    JSR sound_load 
    
    PLA
    TAX
    
    CheckNextEnemyBulletCollision:
    
    INX
    INX
    INX
    INX
    INX
    INX
    
    CPX enemyBulletIndex
    BNE CheckEnemyBulletCollisionLoop

  CheckEnemyBulletCollisionDone:
    
    RTS
    
;;;;;;;;;;;;;;;;;

UpdatePlayerSprites:
  LDA needsSpriteUpdate
  BEQ UpdatePlayerSpritesDone
  
  LDA playerState
  CMP #STATE_PLAYER_ALIVE
  BNE CheckPlayerSpritesDying

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
  ADC #$08
  STA PLAYER_SPRITE+$18
    
  ; horiz
  LDA playerX
  
  STA PLAYER_SPRITE+$3
  STA PLAYER_SPRITE+$B     
  STA PLAYER_SPRITE+$13
  CLC
  ADC #$04
  STA PLAYER_SPRITE+$1B
  CLC
  ADC #$04
  STA PLAYER_SPRITE+$7
  STA PLAYER_SPRITE+$F
  STA PLAYER_SPRITE+$17
  
  ;"flicker" the engine
  LDX engineFlickerDelay
  CPX #$00
  BNE DecEngineFlickerDelay
  
  ; the "flicker" for now is just mirroring the image back and forth
  LDA PLAYER_SPRITE+$1A
  EOR #%01000000
  ORA #%00000001
  STA PLAYER_SPRITE+$1A
  
  LDX #ENGINE_FLICKER_DELAY
  STX engineFlickerDelay
  
  DecEngineFlickerDelay:
    DEC engineFlickerDelay
  
  INC needDMA
  
  JMP UpdatePlayerSpritesCheckStateDone
  
  CheckPlayerSpritesDying:
  
  LDA playerState
  CMP #STATE_PLAYER_DYING
  BNE CheckPlayerSpritesDead
  
  JSR HandlePlayerDyingSprites
  
  INC needDMA

  CheckPlayerSpritesDead:
  
  LDA playerState
  CMP #STATE_PLAYER_DEAD
  BNE UpdatePlayerSpritesCheckStateDone
  
  JSR HandlePlayerDeadSprites
  
  INC needDMA
  
  UpdatePlayerSpritesCheckStateDone:
  
  JSR DisplayPlayerBullets
  
  UpdatePlayerSpritesDone:
    RTS

;;;;;;;;;;;;;;;;
HandlePlayerDeadSprites:

  LDA #$FE
  LDX #$00
  
  CleanPlayerSpritesLoop:
    STA #PLAYER_SPRITE, x
  
    INX
    CPX #$1C
    BNE CleanPlayerSpritesLoop
    
  RTS
  
;;;;;;;;;;;;;;;;

HandlePlayerDyingSprites:
  LDA engineFlickerDelay
  BNE DecExplosionDelay

  ; just need to update the tiles here since the explosion(s) are right where the player was
  LDA frameCounter
  
  ; going to modulo the counter to get the frame    
  PHA
    
  LDA #MAX_EXPLOSION_FRAMES
  PHA
    
  JSR Mod
    
  ; get the return value and also clean up
  PLA        
  PLA
  TAX
    
  LDA explosionAnim, x
  
  STA #PLAYER_SPRITE+$1
  STA #PLAYER_SPRITE+$5
  STA #PLAYER_SPRITE+$9
  STA #PLAYER_SPRITE+$D
  STA #PLAYER_SPRITE+$11
  STA #PLAYER_SPRITE+$15
  STA #PLAYER_SPRITE+$19
  
  ; palette (only if different)
  LDA #PLAYER_SPRITE+$2
  CMP #$01
  BEQ PaletteCheckDone
  
  LDA #$01
  STA #PLAYER_SPRITE+$2
  STA #PLAYER_SPRITE+$6
  STA #PLAYER_SPRITE+$A
  STA #PLAYER_SPRITE+$E
  STA #PLAYER_SPRITE+$12
  STA #PLAYER_SPRITE+$16
  STA #PLAYER_SPRITE+$1A
  
  PaletteCheckDone:
    ; increment the frame
    INC frameCounter
    
    ; reset the delay
    LDA #EXPLOSION_FRAME_DELAY
    STA engineFlickerDelay  
  
    JMP HandlePlayerDyingSpritesDone
    
  DecExplosionDelay:
    DEC engineFlickerDelay
        
  HandlePlayerDyingSpritesDone:
    RTS
  
;;;;;;;;;;;;;;;

UpdatePlayerBullets:
  ; TODO: Figure out when the last bullet has just been removed so we can save future sprite updates until necessary.
  INC needsSpriteUpdate
  
  LDA bulletCount
  CMP #$00
  BEQ RemoveFirstBulletEntry

  LDX #$00  ; current index into bullets
  LDY #$00  ; updated index into bullets
  
  ; we need to ensure we remove any 'dead' bullets in between 'live' ones, and also update their positions
  UpdatePlayerBulletsLoop:
  
    LDA bullets+$1, x
   
    SEC
    SBC #BULLET_SPEED
    
    CMP #MIN_Y_POS_BULLET
    BCC DestroyBullet ; if we've gone off the min Y of the screen as set, this bullet is history

    ; move the bullet forward
    STA bullets+$1, y
    
    LDA bullets, x
    STA bullets, y
    
    INY
    INY
    
    UpdatePlayerBulletsLoopContinue:
      ;;;;; 1
      INX
      INX
      CPX bulletIndex
      BNE UpdatePlayerBulletsLoop ; (old) if the CPX instruction above doesn't set the carry flag, i.e. X < bulletIndex, then continue
    
    
  ; need to go over the array again since the old values still remain, i.e. deal with the new redundancies
  
  ; if no more bullets, well, we're done
  CPY #$00
  BEQ NoMoreBullets
  
  ; if the index remains the same, then nothing to clean up
  CPY bulletIndex
  STY bulletIndex
  BEQ UpdatePlayerBulletsDone
  
  ;;;;;;;;;;;;; 1
  ;DEY
  ;DEY
  ;STY bulletIndex
  
  ;INY
  ;INY

  DEX

  RemoveRedundantBullets:
    LDA #$00
    STA bullets, x
    ;STA bullets+$1, y
    
    DEX
    CPX bulletIndex
    BCS RemoveRedundantBullets
        
  UpdatePlayerBulletsDone:
    RTS

  RemoveFirstBulletEntry:
    LDA #$00
    STA bullets
    STA bullets+$1
    JMP UpdatePlayerBulletsDone

  DestroyBullet:
    DEC bulletCount
    JMP UpdatePlayerBulletsLoopContinue

  NoMoreBullets:
    LDA #$00
    STA bulletIndex
    JMP UpdatePlayerBulletsDone
    
;;;;;;;;;;;;;;;;

DisplayPlayerBullets:
  INC needDMA
  
  ; if we have an empty bullet count, we may need to remove the first bullet there, but have to do a bit of trickery since underflow prevents a normal lookup
  LDA bulletCount
  CMP #$00
  BEQ RemoveFirstBullet
  
  ;LDX #$FE ; off-screen bullet index
  LDX #$00
  LDY #$00 ; on-screen bullet sprite index
  
  DisplayPlayerBulletsLoop:
    ;INX
    ;INX  ; gets us to 0, i.e. first index of bullets
    
    ; vert
    LDA bullets+$1, x
    STA #BULLET_SPRITE, y
    
    ; tile
    LDA #$07
    STA #BULLET_SPRITE+$1, y
    
    ; attribs
    LDA #$02
    STA #BULLET_SPRITE+$2, y  ; since palette is same as tile here

    ; horiz
    LDA bullets, x
    STA #BULLET_SPRITE+$3, y
    
    ; advance y register to next sprite, 4 bytes ahead
    INY
    INY
    INY
    INY

    ;;;;;;;; 1
    INX
    INX
        
    CPX bulletIndex
    BNE DisplayPlayerBulletsLoop
  
  ; need to check for bullets to remove that have expired/gone off the screen
  RemoveExpiredBullets:
    ; TODO: Look at why commenting this out doesn't produce as many "stuck" bullets on the screen after firing a lot.
    ; don't go past the max bullets we can hold
    ;CPY #MAX_PLAYER_BULLETS_INDEX
    ;BEQ DisplayPlayerBulletsDone
    
    ; if this bullet is non-existent, then we're done (we assume that we've cleaned up the array so that any non-existent sprites aren't in the middle of valid ones)
    LDA #BULLET_SPRITE, y
    CMP #$FE
    BEQ DisplayPlayerBulletsDone
    
    LDA #$FE
    STA #BULLET_SPRITE, y
    
    INY
    JMP RemoveExpiredBullets    
  
  RemoveFirstBullet:
    LDX #$FE  ; value to clear out first spirte
    STX #BULLET_SPRITE
    STX #BULLET_SPRITE+$1
    STX #BULLET_SPRITE+$2
    STX #BULLET_SPRITE+$3
    INX
    INX
    STX bullets   ; zero these out; $FE + $02 = $00
    STX bullets+1
    
  DisplayPlayerBulletsDone:
    RTS

;;;;;;;;;;;;;;;;;;; 
DoShoot:
  LDA bulletCount
  CMP #MAX_PLAYER_BULLETS
  BEQ DoShootDelay ; do something else, actually, since this is the limit of the # of bullets we track

  LDA playerShootSalvo
  BEQ DoShootDelay    ; if we hit zero shots left in the salvo, cool down
  
  DEC playerShootSalvo

  ;LDA bulletCount
    
  INC bulletCount
  LDA bulletCount
  CLC
  ADC bulletCount
  
  TAX ; need bulletCount * 2 to store X info, and use this to get the index
  ;DEX ; decrement for 0-based counter

  STX bulletIndex
    
  DEX
  DEX 
  
  LDA playerX
  CLC
  ADC #$04
  STA bullets, x
  
  LDA playerY
  STA bullets+$1, x 
  
  LDA #SOUND_BULLET_IDX
  JSR sound_load
    
  JMP DoShootDone
   
  DoShootDelay:
    LDA #$01
    STA playerShootDelay
   
  DoShootDone:
  	RTS
  	
 ;;;;;;;;;;;;;;
 
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
 
 ;;;;;;;;;;;;;;
 
 playerSprites:
     ;vert tile attr horiz

  ; ship 
  .db $D5, $00, $00, $80   ;sprite 1
  .db $D5, $01, $00, $88   ;sprite 2
  .db $DD, $02, $00, $80   ;sprite 3
  .db $DD, $03, $00, $88   ;sprite 4
  .db $E5, $04, $00, $80   ;sprite 5
  .db $E5, $05, $00, $88   ;sprite 6

  ;; engine
  .db $ED, $06, $01, $84   ;sprite 6
 
  ;; bullet
  .db $00, $07, $02, $00   ;sprite 7
 