; TODO: Need to rework how enemies are tracked, especially after destruction.
; Idea: Give each enemy a position in the array, but still track enemy 'count' for a little optimization when looping through enemies.
; Having a state machine that applies to each enemy (as opposed to treating all enemies as a whole) has proven a bit cumbersome in assembly, but, is still doable, I think.

;;;;;;;;;;;;;;
 
; variables
ENUM $003C
  enemies: .dsb 48   ; (centreX, centreY, degrees, attackDelay, numFired, actualX, actualY, state) do this similar to bullets (8 bytes x 6 enemies)
  enemyBullets: .dsb 36 ; (x, y, tile, palette, frameCounter, enemyIndex) => 6 bytes x 6 bullets)
  enemyExplosions: .dsb 24 ; (x, y, frame, frameDelay) => (4 bytes x 6 enemies)
  enemyCount: .dsb 1
  enemyIndex: .word 1
  enemyDegrees: .dsb 1
  enemyBulletCount: .dsb 1
  enemyBulletIndex: .dsw 1
  enemyExplosionCount: .dsb 1

  tempPos: .dsb 1
  tempTrigAmount: .dsb 1
  tempBVar: .dsb 1
  enemyDelay: .dsb 1
ENDE

;;;;;;;;;;;

; constants
ENEMY_SPRITE = $0234
ENEMY_META_SPRITE_INTERVAL = $10
ATTACK_SPRITE = $0294 
ENEMY_EXPLOSION_SPRITE = $02C4
NUM_ENEMIES_L1 = $03
TRIG_CENTRE = $20
ATTACK_DELAY = $0F
ENEMY_BULLET_SPEED = $02
MAX_TOTAL_ENEMY_BULLET_COUNT = $04
MAX_ENEMY_BULLET_COUNT = $02
MAX_ENEMY_BULLET_INDEX = $28 ; $24, but should be one sprite past
MAX_ENEMY_INDEX = $30
EXPLOSION_FRAME_DELAY = $04
MAX_EXPLOSION_FRAMES = $03
MAX_EXPLOSION_INDEX = $30
MIN_X_POS = $2B
MAX_X_POS = $E8
MIN_Y_POS_ENEMY = $09
MAX_Y_POS_ENEMY = $20

STATE_ENEMY_ALIVE = $01
STATE_ENEMY_DYING = $02
STATE_ENEMY_OFF_SCREEN = $03
STATE_ENEMY_CLEANUP = $04
STATE_ENEMY_DEAD = $FE
STATE_ENEMY_REMOVE = $FD
STATE_ENEMY_WAITING = $FC

;;;;;;;;;;;;;

InitiEnemyVars:
  LDA #NUM_ENEMIES_L1
  STA enemyCount
  
  JSR InitEnemies
  
  LDA #$00
  STA enemyDegrees
  STA enemyBulletCount
  STA enemyBulletIndex
  STA enemyExplosionCount
  STA enemyDelay
  
  LDA #$00
  LDX #$00
  
  InitEnemyBulletsLoop:
    STA enemyBullets, x
    INX
    CPX #MAX_ENEMY_BULLET_INDEX
    BNE InitEnemyBulletsLoop
  
  RTS
;;;;;;;;;;;;;

IncEnemyIndexX:
  INX
  INX
  INX
  INX
  INX
  INX
  INX
  INX
  
  RTS

DecEnemyIndexX:
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  
  RTS
  
IncEnemyIndexY:
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  
  RTS

DecEnemyIndexY:
  DEY
  DEY
  DEY
  DEY
  DEY
  DEY
  DEY
  DEY
  
  RTS

;;;;;;;;;;;;;

GenerateRandomXPos:

    JSR RNG
    
    TXA
    PHA
    
    LDA seed
    CLC
    ADC #$20
    
    PHA
    
    LDA #$F0
    
    PHA
    
    JSR Mod    
    
    PLA
    
    ; modded number
    PLA
    
    ; let's make sure it's within a decent range
    CMP #MIN_X_POS
    BCS CheckMaxX
    
    LDA #MIN_X_POS  
    JMP SaveRandomXPos
    
    CheckMaxX:
      CMP #MAX_X_POS
      BCC SaveRandomXPos
      
      LDA #MAX_X_POS

    SaveRandomXPos:
      STA tempBVar
    
    ; still need to fetch x register since we used it in mod
    PLA
    TAX
    
    LDA tempBVar
    
    RTS

;;;;;;;;;;;;

GenerateRandomYPos:

    JSR RNG
    
    TXA
    PHA
    
    LDA seed
    
    PHA
    
    LDA #$D0
    
    PHA
    
    JSR Mod    
    
    PLA
    
    ; modded number
    PLA
    
    CMP #MIN_Y_POS_ENEMY
    BCS SkipMinY

    LDA #MIN_Y_POS_ENEMY
 
    JMP GenerateRandomYPosDone
    
    SkipMinY:
    
      CMP #MAX_Y_POS_ENEMY
      BCC GenerateRandomYPosDone
    
      LDA #MAX_Y_POS_ENEMY
    
    GenerateRandomYPosDone:
    
    STA tempBVar
    
    ; still need to fetch x register since we used it in mod
    PLA
    TAX
    
    LDA tempBVar
    
    RTS

;;;;;;;;;;;;

InitEnemies:
  LDX #$00
  LDY #$00
  
  InitEnemiesLoop:
    JSR InitEnemy
  
    JSR IncEnemyIndexX
        
    INY
    
    CPY enemyCount
    BNE InitEnemiesLoop
    
    ; save the last index (actually just past)
    STX enemyIndex
    
  RTS

;;;;;;;;;;;;;

InitEnemy: 
    LDA #ATTACK_DELAY
    STA enemies+$3, x
  
    JSR GenerateRandomYPos
    LDA tempBVar
    
  	STA enemies+$1, x ; y-coordinate  	
    STA enemies+$6, x
  
    JSR GenerateRandomXPos
    
    LDA tempBVar        

    STA enemies, x  ; x-coordinate
    STA enemies+$5, x      
    STA enemies+$4, x
    
    ; degrees
    LDA #$00
    STA enemies+$2, x
      
    LDA #STATE_ENEMY_ALIVE
    STA enemies+$7, x
  
  RTS

;;;;;;;;;;;;;

; possibly unnecessary...
LoadEnemySprites:
  LDX #$00              ; start at 0
LoadEnemySpritesLoop:
  LDA enemySprites, x        ; load data from address (sprites + x)
  STA #ENEMY_SPRITE, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$10              ; Compare X to hex $18, decimal 24
  BNE LoadEnemySpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 16, keep going down

  
  RTS

;;;;;;;;;;;

CheckPlayerBulletCollision:
  LDA bulletCount
  BEQ CheckPlayerCollisionDone
    
  LDX #$00  ; player bullet index
  LDY #$00  ; enemy index
  
  CheckPlayerBulletCollisionLoop:
    CLC
    
    ; check x
    LDA bullets, x
    SBC enemies+$5, y
    SBC #$10-1 ; enemy size
    ADC #$08+$10-1
    BCC CheckNextPlayerBulletCollision
    
    CLC
    
    ; check y if carry is set
    LDA bullets+$1, x
    SBC enemies+$6, y
    SBC #$10-1 ; enemy size
    ADC #$08+$10-1
    BCC CheckNextPlayerBulletCollision
    
    ; collision!

    ;LDA score
    ;CLC
    ;ADC #ENEMY_POINT_VALUE
    ;STA score

	LDA #<Points100
	STA AL
	LDA #>Points100
	STA AH
	
	TXA
	PHA
	TYA
	PHA
        
    JSR AddPoints
    
    PLA
    TAY
    PLA
    TAX
    
    LDA #STATE_ENEMY_DYING
    STA enemies+$7, y
    
    CheckNextPlayerBulletCollision:
    
    INX
    INX
    
    JSR IncEnemyIndexY
        
    CPX bulletIndex
    BNE CheckPlayerBulletCollisionLoop

  CheckPlayerCollisionDone:
    ;JSR CleanEnemies
    
    RTS

;;;;;;;;;;;
ExpireEnemy:

    LDA #$FE
    STA enemies, x
    STA enemies+$1, x
    STA enemies+$2, x
    STA enemies+$3, x
    STA enemies+$4, x
    STA enemies+$5, x
    STA enemies+$6, x

  RTS

;;;;;;;;;;

EnemyDeadBehaviour:
  ; for now, enemies' index is twice that of enemyExplosions, so, we need to halve it to get the explosion index
  
  ; skip any math if it's index 0
  CPX #$00
  BEQ DoUpdateDeadEnemy
  
  TXA
  PHA
  
  LSR
  
  TAX
  
  DoUpdateDeadEnemy:
  
  LDA #$00
  STA enemyExplosions, x
  STA enemyExplosions+$1, x
  STA enemyExplosions+$2, x
  STA enemyExplosions+$3, x
    
  CPX #$00
  BEQ UpdateDeadEnemyDone

  PLA
  TAX

  UpdateDeadEnemyDone:
  
  LDA #STATE_ENEMY_CLEANUP
  STA enemies+$7, x

  RTS

;;;;;;;;;;;

EnemyDyingBehaviour:
  TXA
  LSR
  TAY

  LDA enemies, x
  CMP #$FE
  BNE InitEnemyExplosion
    
  ; only allow the explosion animation to go for so long...  
  LDA enemyExplosions+$2, y
  CMP #MAX_EXPLOSION_FRAMES
  BNE ClearEnemySpriteContinue
  
  ; if we're at the max explosion count, set this enemy as dead
  LDA #STATE_ENEMY_DEAD
  STA enemies+$7, x
  
  JMP EnemyDyingBehaviourDone
    
  ClearEnemySpriteContinue:
  
	  ;DEC enemyExplosions+$3, y
	  LDA enemyExplosions+$3, y
	  SEC
	  SBC #$01
	  STA enemyExplosions+$3, y
	  ;LDA enemyExplosions+$3, y
	  
	  BNE EnemyDyingBehaviourDone
	  
	  ; increase the frame counter and reset the frame counter delay
	  ;INC enemyExplosions+$2, y
	  LDA enemyExplosions+$2, y
	  CLC
	  ADC #$01
	  STA enemyExplosions+$2, y
	  
	  LDA #EXPLOSION_FRAME_DELAY
	  STA enemyExplosions+$3, y  
	  
	  JMP EnemyDyingBehaviourDone
	  
  ; init the explosion
  InitEnemyExplosion:
	  
	  LDA enemies+$5, x
	  CLC
	  ADC #$04
	  STA enemyExplosions, y
	  
	  LDA enemies+$6, x
	  CLC
	  ADC #$04
	  STA enemyExplosions+$1, y
	  
	  LDA #$00
	  STA enemyExplosions+$2, y
	  
	  LDA #EXPLOSION_FRAME_DELAY
	  STA enemyExplosions+$3, y
	  
	  JSR ExpireEnemy
	  
	  INC enemyExplosionCount
  
  EnemyDyingBehaviourDone:
  	RTS

;;;;;;;;;;;

EnemyAliveBehaviour:
 
   LDA enemies+$6, x
   
   CMP #$EF
   BCC EnemyAliveContinue
   
   LDA #STATE_ENEMY_OFF_SCREEN
   STA enemies+$7, x
   
   JMP EnemyAliveBehaviourDone
   
   EnemyAliveContinue:
   ; for this behaviour, go in circles until halfway down the screen; then just go normal like
   CMP #$77
   BCS EnemyGoStraight
   
    ; horiz
    LDA enemies, x
    STA tempPos
    
    LDA enemies+$2, x
    STA enemyDegrees
    
    TXA
    PHA
    
    LDX enemyDegrees
    LDA sine, x
    
    SEC
    SBC #TRIG_CENTRE
    STA tempTrigAmount
    BMI SubEnemyX
    
    ; clearing the carry flag allows for proper addition; otherwise, it will properly "add" a negative number     
    CLC
    
    SubEnemyX:
    LDA tempPos
    ADC tempTrigAmount
    STA tempPos
              
    PLA
    TAX
      
    ; store actual x
    LDA tempPos
    STA enemies+$5, x
      
    ; vert   
    LDA enemies+$1, x
    STA tempPos
    
    TXA
    PHA
    
    LDX enemyDegrees
    LDA cosine, x
    
    SEC
    SBC #TRIG_CENTRE
    STA tempTrigAmount
    BPL SubEnemyY
    
    SEC
    
    SubEnemyY:
    LDA tempPos
    SBC tempTrigAmount
    STA tempPos
    
    PLA
    TAX
    
    ; store actual y
    LDA tempPos
    STA enemies+$6, x   
     
    ; increment angle
	INC enemies+$2, x
	INC enemies+$2, x
	INC enemies+$2, x
    
    INC enemies+$1, x
    
    JMP EnemyAliveBehaviourDone
      
    EnemyGoStraight:      
      INC enemies+$1, x
      INC enemies+$6, x
    
    EnemyAliveBehaviourDone:
      
  RTS

;;;;;;;;;;;

EnemyOffScreenBehaviour:

  JSR ExpireEnemy

  LDA #STATE_ENEMY_REMOVE
  STA enemies+$7, x

  RTS

;;;;;;;;;;;

FindFirstWaitingEnemy:

  LDX #$00
  
  FindFirstWaitingEnemyLoop:
    CPX enemyIndex
    BEQ FindFirstWaitingEnemyDone
  
    LDA enemies+$7, x
    CMP #STATE_ENEMY_WAITING
    BEQ FindFirstWaitingEnemyDone
    
    JSR IncEnemyIndexX
    
    JMP FindFirstWaitingEnemyLoop

  FindFirstWaitingEnemyDone:
    RTS
    
;;;;;;;;;;;

EnemySpawnCheck:

  DEC enemyDelay
  BMI ResetEnemyDelay
  BEQ SpawnEnemy
  
  JMP EnemySpawnCheckEnd
  
  SpawnEnemy:
    ; need to find the first available position to 'spawn' a new enemy
    ;LDX enemyIndex
	JSR FindFirstWaitingEnemy  ; value is stored in X
    
    JSR InitEnemy
    
    ; reset the y-coordinate (centre and actual)
    ;LDA #$00
    ;STA enemies+$1, x
    ;STA enemies+$6, x
    
    ;JSR IncEnemyIndexX
    ;STX enemyIndex
    
    INC enemyCount  

    JMP EnemySpawnCheckEnd
  
  ResetEnemyDelay:
    JSR RNG
    LDA seed
    STA enemyDelay
  
  EnemySpawnCheckEnd:
    RTS

;;;;;;;;;;;

DoEnemyBehaviour:
  LDA enemyCount
  CMP #NUM_ENEMIES_L1
  BCS SkipEnemySpawnCheck
  
  JSR EnemySpawnCheck
  
  SkipEnemySpawnCheck:
  
	  JSR UpdateEnemyFire  ; update any existing bullets
	
	  JSR CheckPlayerBulletCollision
	  
	  LDA enemyCount
	  BEQ DoEnemyBehaviourDone
	  
	  ; this can/should be done outside of a state check since it can exist independent of an enemy
	  JSR EnemyBulletUpdate
	  
	  LDX #$00
  
  EnemyStateLoop:
    LDA enemies+$7, x  ; state
    
    CMP #STATE_ENEMY_ALIVE
    BNE DyingStateCheck
    
    JSR EnemyAliveBehaviour
    
    JMP EnemyStateLoopCheck
  
    DyingStateCheck:
    
    CMP #STATE_ENEMY_DYING
    BNE OffScreenStateCheck
    
    JSR EnemyDyingBehaviour
    
    JMP EnemyStateLoopCheck
    
    OffScreenStateCheck:
    
    CMP #STATE_ENEMY_OFF_SCREEN
    BNE DeadStateCheck
    
    JSR EnemyOffScreenBehaviour
    
    JMP EnemyStateLoopCheck
    
    DeadStateCheck:
    
    CMP #STATE_ENEMY_DEAD
    BNE RemoveStateCheck
    
    JSR EnemyDeadBehaviour
    
    JMP EnemyStateLoopCheck
    
    RemoveStateCheck:
    
    CMP #STATE_ENEMY_REMOVE
    BNE EnemyStateLoopCheck
    
    DEC enemyCount
    
    LDA #STATE_ENEMY_WAITING
    STA enemies+$7, x
    
    EnemyStateLoopCheck:

    JSR IncEnemyIndexX
    
    CPX enemyIndex
    BEQ DoEnemyBehaviourDone
    
    JMP EnemyStateLoop
     
  DoEnemyBehaviourDone:
  
  ;JSR CleanEnemies
  
  RTS

;;;;;;;;;;;;
EnemyBulletUpdate:

  LDA enemyBulletCount
  CMP #MAX_TOTAL_ENEMY_BULLET_COUNT
  BCS EnemyBulletUpdateDone    

  LDX #$00 ; index for enemies var
  LDY enemyBulletIndex ; index for enemies' bullets
  
  EnemyBulletLoop:
    ; only create bullets for enemies who are alive
    LDA enemies+$7, x
    CMP #STATE_ENEMY_ALIVE
    BNE EnemyBulletLoopCheck
  
    LDA enemies+$3, x
    BEQ InitEnemyBullet
   
    DEC enemies+$3, x
    
    JMP EnemyBulletLoopCheck    
     
    InitEnemyBullet:    
      LDA enemies+$4, x
      CMP #MAX_ENEMY_BULLET_COUNT
      BEQ EnemyBulletLoopCheck
      
      ; reset the attack delay
      LDA #ATTACK_DELAY
      STA enemies+$3, x
      
      INC enemyBulletCount
      INC enemies+$4, x ; up the current bullet count for this enemy

      ; need the (x,y) of the enemy AFTER the trig has been applied
      
      ; x
      LDA enemies+$5, x
      STA enemyBullets, y
      
      ; y
      LDA enemies+$6, x
      CLC
      ADC #$08
      STA enemyBullets+$1, y
      
      LDA #$14
      STA enemyBullets+$2, y
      
      LDA #$00
      STA enemyBullets+$3, y
      STA enemyBullets+$4, y
      
      ; need to store enemy index
      STX enemyBullets+$5, y      
            
      INY
      INY
      INY
      INY
      INY
      INY
    
    EnemyBulletLoopCheck:
      JSR IncEnemyIndexX
            
      CPX enemyIndex
      BNE EnemyBulletLoop
      
      STY enemyBulletIndex  
      
    EnemyBulletUpdateDone:
      RTS


;;;;;;;;;;;;


UpdateEnemyFire:
  LDA enemyBulletCount
  BNE UpdateEnemyFireDoneJumpContinue

  JMP UpdateEnemyFireDone

  UpdateEnemyFireDoneJumpContinue:
  
  ; need to get rid of old bullets...
  LDX #$00  ; old bullet index
  LDY #$00  ; new bullet index
  
  UpdateEnemyFireLoop:
      ; y
      LDA enemyBullets+$1, x
      CLC
      ADC #ENEMY_BULLET_SPEED
      
      CMP #$EF
      BCC GoodBullet
      
      BadBullet:
      TXA
      PHA
            
      DEC enemyBulletCount
      
      LDA enemyBullets+$5, x  ; get enemy index
      
      TAX
      DEC enemies+$4, x  ; decrement the bullet count for that enemy
      
      PLA
      TAX
      
      JMP BulletContinue
      
      GoodBullet:
      STA enemyBullets+$1, y
      
      ; x
      LDA enemyBullets, x
      STA enemyBullets, y
      
      ; tile
      LDA enemyBullets+$2, x
      CLC
      ADC #$02
      CMP #$1A
      BNE SkipLockTile
      
      SEC
      SBC #$02
      
      SkipLockTile:
        STA enemyBullets+$2, y
        
      ; palette
      LDA enemyBullets+$3, x
      CLC
      ADC #$01
      CMP #$05
      BNE SkipPaletteCycle
      
      LDA #$00
      
      SkipPaletteCycle:
        STA enemyBullets+$3, y
        
      LDA enemyBullets+$4, x
      CLC
      ADC #$01
      CMP #$FF
      BNE SkipCountLock
      LDA #$FE
      
      SkipCountLock:
        STA enemyBullets+$4, y
      
      LDA enemyBullets+$5, x
      STA enemyBullets+$5, y
              
      INY
      INY
      INY
      INY
      INY      
      INY
      
      BulletContinue:
      INX
      INX
      INX
      INX
      INX
      INX
      
      CPX enemyBulletIndex
      BNE UpdateEnemyFireLoop

  ; values have all been moved up one in most cases...get rid of the excess
  ;CPY #$00
  ;BEQ DoneBullets
    
  ; if the index remains the same, then nothing to clean up
  CPY enemyBulletIndex
  STY enemyBulletIndex  
  BEQ DoneBullets    
  
  DEX
  BMI DoneBullets
  
  ClearExcessBullets:
    LDA #$00
    STA enemyBullets, x
    
    DEX
    CPX enemyBulletIndex
    BPL ClearExcessBullets ; if we use BNE, this won't clear what's at enemyBulletIndex, so use positive
    
    JMP UpdateEnemyFireDone    
  
  DoneBullets:

  UpdateEnemyFireDone:
    RTS

;;;;;;;;;;;

UpdateAliveEnemy:
    ; horiz
    LDA enemies+$5, x
    STA #ENEMY_SPRITE+$3, y
    STA #ENEMY_SPRITE+$B, y
    CLC
    ADC #$08
    STA #ENEMY_SPRITE+$7, y      
    STA #ENEMY_SPRITE+$F, y
            
    ; vert   
    LDA enemies+$6, x
    STA #ENEMY_SPRITE, y
    STA #ENEMY_SPRITE+$4, y
    CLC
    ADC #$08
    STA #ENEMY_SPRITE+$8, y
    STA #ENEMY_SPRITE+$C, y

    ; tile
    LDA #$10
    STA #ENEMY_SPRITE+$1, y
    LDA #$11
    STA #ENEMY_SPRITE+$5, y
    LDA #$12
    STA #ENEMY_SPRITE+$9, y
    LDA #$13
    STA #ENEMY_SPRITE+$D, y
    
    ; attrs
    LDA #$03
    STA #ENEMY_SPRITE+$2, y
    STA #ENEMY_SPRITE+$6, y
    STA #ENEMY_SPRITE+$A, y
    STA #ENEMY_SPRITE+$E, y

    INC needDMA
     
  RTS

;;;;;;;;;;;


; TODO: Explosions are currently tied to enemy index (8 as opposed to 4) and this probably needs changing.

ClearEnemySprite:

	; can probably optimize further by introudcing a new state?
	LDA #ENEMY_SPRITE, y
	CMP #$FE
	BEQ ClearEnemySpriteDone

    LDA #$FE
  
    ; need to clear out enemy sprites          
    STA #ENEMY_SPRITE, y
    STA #ENEMY_SPRITE+$1, y
    STA #ENEMY_SPRITE+$2, y
    STA #ENEMY_SPRITE+$3, y
    
    STA #ENEMY_SPRITE+$4, y
    STA #ENEMY_SPRITE+$5, y
    STA #ENEMY_SPRITE+$6, y
    STA #ENEMY_SPRITE+$7, y

    STA #ENEMY_SPRITE+$8, y
    STA #ENEMY_SPRITE+$9, y
    STA #ENEMY_SPRITE+$A, y
    STA #ENEMY_SPRITE+$B, y

    STA #ENEMY_SPRITE+$C, y
    STA #ENEMY_SPRITE+$D, y
    STA #ENEMY_SPRITE+$E, y
    STA #ENEMY_SPRITE+$F, y
  
    INC needDMA
 
  ClearEnemySpriteDone:
    RTS
;;;;;;;;;;;

UpdateCleanupEnemy:

    TXA
    PHA
    TYA
    PHA    
    
    JSR DrawExplosion

	PLA
	TAY
	PLA
	TAX
	
	LDA #STATE_ENEMY_REMOVE
    STA enemies+$7, x
    	
  RTS

;;;;;;;;;;;

UpdateEnemySprites:
  LDX #$00 ; index for enemies var
  LDY #$00 ; meta-sprite index

  LDA enemyCount
  BNE UpdateEnemySpritesLoop 
  
  JMP UpdateEnemyNext  
  
  UpdateEnemySpritesLoop:
    LDA enemies+$7, x ; state
    CMP #STATE_ENEMY_ALIVE
    BNE UpdateEnemyCheckDyingState
    
    JSR UpdateAliveEnemy
    
    JMP UpdateEnemySpritesLoopCheck
    
    UpdateEnemyCheckDyingState:
    
    LDA enemies+$7, x ; state
    CMP #STATE_ENEMY_DYING
    BNE UpdateEnemyCheckCleanupState
    
    JSR ClearEnemySprite
    
    TXA
    PHA
    TYA
    PHA    
    
    JSR DrawExplosion

	PLA
	TAY
	PLA
	TAX
	    
    JMP UpdateEnemySpritesLoopCheck

    UpdateEnemyCheckCleanupState:
    
    LDA enemies+$7, x ; state
    CMP #STATE_ENEMY_CLEANUP
    BNE UpdateEnemyCheckOffScreenState
    
    JSR UpdateCleanupEnemy
    
    JMP UpdateEnemySpritesLoopCheck

	UpdateEnemyCheckOffScreenState:

    LDA enemies+$7, x ; state
    CMP #STATE_ENEMY_OFF_SCREEN
    BNE UpdateEnemySpritesLoopCheck
    
	JSR ClearEnemySprite

    UpdateEnemySpritesLoopCheck:
    
    JSR IncEnemyIndexX    
    
    ; increase the meta sprite index for drawing
	TYA
    CLC
    ADC #ENEMY_META_SPRITE_INTERVAL
    TAY
    
    CPX enemyIndex
    BNE UpdateEnemySpritesLoopJump
    
    JMP UpdateEnemyNext        
    
  UpdateEnemySpritesLoopJump:
    JMP UpdateEnemySpritesLoop
    
  UpdateEnemyNext:
    
  UpdateEnemySpritesDone:
  
  JSR DrawEnemyFire
  
  UpdateEnemySpritesRTS:
    RTS
    
;;;;;;;;;;;;;;;;;;;;;
DrawExplosion:
	INC needDMA
	
	; explosion index is half of enemies index; we also need explosion number her for the purpose of addressing the right explosion sprite
	TXA

	LSR
	
	TAX
	
	LSR
	LSR
	
	; now need to get appropriate offset for addressing explosion sprite
	STA tempBVar
	LDA #$00
	LDY #$00	
	
	DEGetExplosionIndexLoop:
	  CMP tempBVar
	  BEQ DEGetExplosionIndexLoopDone

	  INY
	  INY
	  INY
	  INY
	  
	  CLC
	  ADC #$01
	  
	  JMP DEGetExplosionIndexLoop

	DEGetExplosionIndexLoopDone:
	
    ; x
    LDA enemyExplosions, x
    STA #ENEMY_EXPLOSION_SPRITE+$3, y  
  
    ; y
    LDA enemyExplosions+$1, x
    STA #ENEMY_EXPLOSION_SPRITE, y
    
    ; tile
    TXA
    PHA
    
    LDA enemyExplosions+$2, x
    
    ; going to modulo the counter to get the frame    
    PHA
    
    LDA #$04
    PHA
    
    JSR Mod
    
    ; get the return value and also clean up
    PLA        
    PLA
    TAX
    
    LDA explosionAnim, x
    STA #ENEMY_EXPLOSION_SPRITE+$1, y 
    
    PLA
    TAX

    ; attrs
    LDA #$01 ; just set the palette
    STA #ENEMY_EXPLOSION_SPRITE+$2, y
    
    RTS

;;;;;;;;;;;;;;;;;;;;;

DrawEnemyFire:
  LDA enemyBulletCount
  BEQ DrawEnemyFireDone 
  
  INC needDMA  
  
  LDX #$00
  LDY #$00  
  
  DrawEnemyFireLoop:
    ; vert
    LDA enemyBullets+$1, x
    STA #ATTACK_SPRITE, y
    STA #ATTACK_SPRITE+$4, y
    
    ; tile
    LDA enemyBullets+$2, x
    STA #ATTACK_SPRITE+$1, y
    CLC
    ADC #$01
    STA #ATTACK_SPRITE+$5, y
    
    ; palette
    LDA enemyBullets+$3, x
    STA #ATTACK_SPRITE+$2, y
    STA #ATTACK_SPRITE+$6, y
    
    ; horiz
    LDA enemyBullets, x
    STA #ATTACK_SPRITE+$3, y
    CLC
    ADC #$08
    STA #ATTACK_SPRITE+$7, y
    
    INX
    INX
    INX
    INX
    INX
    INX
    
    TYA
    CLC
    ADC #$08
    TAY
    
    CPX enemyBulletIndex
    ;BNE DrawEnemyFireLoop

    ;CPX #MAX_ENEMY_BULLET_INDEX
    ;LDA #ATTACK_SPRITE, y
    BNE DrawEnemyFireLoop
    
    ;RTS
    
    ; remove any "old" bullets
    RemoveOldBulletSprites:
      CPX #MAX_ENEMY_BULLET_INDEX
      BEQ DrawEnemyFireDone
    
      ; don't do any more than we really need to
      LDA #ATTACK_SPRITE, y
      CMP #$FE
      BEQ DrawEnemyFireDone
    
      LDA #$FE
      STA #ATTACK_SPRITE, y
      STA #ATTACK_SPRITE+$1, y
      STA #ATTACK_SPRITE+$2, y
      STA #ATTACK_SPRITE+$3, y      
    
      INY
      INY
      INY
      INY
      
      ;JSR IncEnemyIndexX
      INX
      INX
      INX
      INX
      INX
      INX
    
      JMP RemoveOldBulletSprites 
    
  DrawEnemyFireDone:
    RTS  
    
;;;;;;;;;;;;;;;;;;;;;    
enemySprites:
   ;vert tile attr horiz

   ;; ship
  .db $00, $10, $03, $00   ;sprite 0
  .db $00, $11, $03, $00   ;sprite 1
  .db $00, $12, $03, $00   ;sprite 2
  .db $00, $13, $03, $00   ;sprite 3

   ;; "bullets"
   .db $00, $14, $00, $00
   .db $00, $16, $00, $00
   .db $00, $18, $00, $00
   
attackAnim:
  .db $14, $16, $18
  
explosionAnim:
  .db $20, $21, $22, $23
  