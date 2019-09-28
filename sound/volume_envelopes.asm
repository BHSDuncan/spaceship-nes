volume_envelopes:
    .word se_ve_1
    .word se_ve_2
    .word se_ve_3
    .word se_ve_tgl_1
    .word se_ve_tgl_2
    .word se_battlekid_loud
    .word se_battlekid_loud_long
    .word se_battlekid_soft
    .word se_battlekid_soft_long
    .word se_drum_decay
    .word se_pm_1
    .word se_long_fade_out
    .word se_long_fade_in
    
se_ve_1:
    .byte $0F, $0E, $0D, $0C, $09, $05, $00
    .byte $FF
se_ve_2:
    .byte $01, $01, $02, $02, $03, $03, $04, $04, $07, $07
    .byte $08, $08, $0A, $0A, $0C, $0C, $0D, $0D, $0E, $0E
    .byte $0F, $0F
    .byte $FF
se_ve_3:
    .byte $0D, $0D, $0D, $0C, $0B, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $06, $06, $06, $05, $04, $00
    .byte $FF
    
se_ve_tgl_1:
    .byte $0F, $0B, $09, $08, $07, $06, $00
    .byte $FF
    
se_ve_tgl_2:
    .byte $0B, $0B, $0A, $09, $08, $07, $06, $06, $06, $05
    .byte $FF
    
se_battlekid_loud:
    .byte $0f, $0e, $0c, $0a, $00
    .byte $FF
    
se_battlekid_loud_long:
    .byte $0f, $0e, $0c, $0a, $09
    .byte $FF
    
se_battlekid_soft:
    .byte $09, $08, $06, $04, $00
    .byte $FF
    
se_battlekid_soft_long:
    .byte $09, $08, $06, $04, $03
    .byte $FF

se_drum_decay:
    .byte $0E, $09, $08, $06, $04, $03, $02, $01, $00  ;7 frames per drum.  Experiment to get the length and attack you want.
    .byte $FF
    
se_pm_1:
    ;.byte $0C, $0A, $09, $07, $01, $00, $00
    .byte $0C, $0A, $09, $07, $00, $00, $04, $02
    .byte $FF

se_long_fade_out:
	;.byte $0F, $0E, $0C, $0A, $09, $06, $04, $03, $02, $02, $01, $01, $00
	.byte $0A, $0C, $0E
	.byte $0F, $0F, $0F, $0F,$0F, $0F,$0F, $0F,$0F, $0F,$0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
	.byte $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C
	.byte $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $09, $07, $07, $07, $07, $07, $07
	.byte $FF    
	
se_long_fade_in:
	;.byte $00, $02, $02, $06, $0A, $0C, $0F, $0F, $0F, $0F, $0D, $0A, $0A, $0A, $0A, $0A, $0D, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0D, $0A, $0A, $0A, $0A, $0A, $0D, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0D, $0A, $0A, $0A, $0A, $0A, $0D, $0F, $0F, $0F, $0F, $0F, $0F, $0F  
	;.byte $01, $02, $06, $08, $0A, $0B, $0B
    .byte $01, $01, $02, $02, $03, $03, $04, $04, $07, $07
    .byte $08, $08, $0A, $0A, $0C, $0C, $0D, $0D, $0E, $0E
    .byte $0F, $0F, $0F, $0F,$0F, $0F,$0F, $0F,$0F, $0F,$0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
    
    .byte $0E, $0E, $0E, $0E, $0E, $0E, $0D, $0D, $0D, $0D, $0D, $0D, $0C, $0C, $0C, $0C, $0C, $0A, $0A, $0A, $0A, $0A, $08, $08
    ;.byte $07, $07, $06, $06, $06, $06, $05, $05, $05, $05
 
	.byte $FF