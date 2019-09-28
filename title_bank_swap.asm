CMP #$00
BNE DoTitleBankSwap 

JMP TitleBankSwapDone

DoTitleBankSwap:

LDA #$00
JSR Bankswitch

LoadTitlePalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadTitlePalettesLoop:
  LDA titlePalette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$10            
  BNE LoadTitlePalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down  

LoadTitleNametable:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address

  LDA #<titleDat
  STA pointerLow
  
  LDA #>titleDat
  STA pointerHigh
  
  LDX #$04
  LDY #$00
  
LoadTitleNametableLoop:
  LDA (pointerLow), y     ; load data from address
  STA $2007             ; write to PPU
  INY
  BNE LoadTitleNametableLoop
  INC pointerHigh
  DEX
  BNE LoadTitleNametableLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

LoadTitleAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadTitleAttributeLoop:
  LDA titleAttrs, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadTitleAttributeLoop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

TitleBankSwapDone: