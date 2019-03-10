
ENUM $05D3
	value: .word 1
	delta: .word 1
	 
	sine: .dsb 256
	cosine: .dsb 256
	
	modValue: .dsb 1
	seed: .dsb 1
ENDE

InitTemps:
 LDA #$00
 STA value
 STA value+1
 STA delta
 STA delta+1

  RTS

InitSineTable:
 JSR InitTemps
  
 ldy #$3f
 ldx #$00
 
; Accumulate the delta (normal 16-bit addition)
SineTableLoop: 
  lda value
  clc
  adc delta
  sta value
  lda value+1
  adc delta+1
  sta value+1
 
; Reflect the value around for a sine wave
  sta sine+$c0,x
  sta sine+$80,y
  eor #$1f
  sta sine+$40,x
  sta sine+$00,y
 
; Increase the delta, which creates the "acceleration" for a parabola
  lda delta
  adc #$02   ; this value adds up to the proper amplitude
  sta delta
  bcc SineTableLoopEnd
   inc delta+1
SineTableLoopEnd:
 
; Loop
  inx
  dey
 bpl SineTableLoop
 
 rts
 
 
InitCosineTable:
 
 JSR InitTemps
 
 ldy #$3f
 ldx #$00
 
; Accumulate the delta (normal 16-bit addition)
CosineTableLoop: 
  lda value
  clc
  adc delta
  sta value
  lda value+1
  adc delta+1
  sta value+1
 
; Reflect the value around for a cosine wave
  sta cosine+$80,x
  sta cosine+$40,y
  eor #$1f
  sta cosine+$00,x
  sta cosine+$c0,y
   
; Increase the delta, which creates the "acceleration" for a parabola
  lda delta
  adc #$02   ; this value adds up to the proper amplitude
  sta delta
  bcc CosineTableLoopEnd
   inc delta+1
CosineTableLoopEnd:
 
; Loop
  inx
  dey
 bpl CosineTableLoop
 
 rts

 ;;;;;;;;;;;;;
 
 Mod:  ; (after RTS top two bytes) top of stack: modulo; next on stack: number
   TSX
   
   LDA #$103, x   
   STA modValue
   
   LDA #$104, x
   
   SEC
   
   ModLoop:
     SBC modValue
     BCS ModLoop
     
   ADC modValue
   
   STA #$104, x
   
   RTS
   
;;;;;;;;;;;;;;;;

RNG:

  LDA seed
  BEQ doEor
  ASL
  BEQ noEor ;if the input was $80, skip the EOR
  BCC noEor

doEor:    
  EOR #$5F

noEor:  
  STA seed
  
  RTS