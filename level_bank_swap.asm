CMP #$00
BNE DoLevelBankSwap 

JMP LevelBankSwapDone

DoLevelBankSwap:

  LDX #$00
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  
;LDA #$01
;JSR Bankswitch

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

LoadBGPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadBGPalettesLoop:
  LDA bgPalette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$10            
  BNE LoadBGPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down  
                        

LoadNametable0:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address

  LDA #<bgdat
  STA pointerLow
  
  LDA #>bgdat
  STA pointerHigh
  
  LDX #$04
  LDY #$00
  
LoadNametable0Loop:
  LDA (pointerLow), y     ; load data from address
  STA $2007             ; write to PPU
  INY
  BNE LoadNametable0Loop
  INC pointerHigh
  DEX
  BNE LoadNametable0Loop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

LoadNametable2:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$28
  STA $2006             ; write the high byte of $2800 address
  LDA #$00
  STA $2006             ; write the low byte of $2800 address

  LDA #<bgdat
  STA pointerLow
  
  LDA #>bgdat
  STA pointerHigh
  
  LDX #$04
  LDY #$00
  
LoadNametable2Loop:
  LDA (pointerLow), y     ; load data from address
  STA $2007             ; write to PPU
  INY
  BNE LoadNametable2Loop
  INC pointerHigh
  DEX
  BNE LoadNametable2Loop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
              
LoadAttribute0:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttribute0Loop:
  LDA bgattrs, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttribute0Loop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

LoadAttribute2:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$2B
  STA $2006             ; write the high byte of $2BC0 address
  LDA #$C0
  STA $2006             ; write the low byte of $2BC0 address
  LDX #$00              ; start out at 0
LoadAttribute2Loop:
  LDA bgattrs, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttribute2Loop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
                  
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 0
  STA $2000
  
  LDA #%00011000   ; enable sprites, enable background, clipping on left side
  STA $2001
                       
LevelBankSwapDone: