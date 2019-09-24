enemy_bullet_sound_header:
	.byte $01           ;1 stream
    
    .byte SFX_2         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2 ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_long_fade_out  ;volume envelope
    .word enemy_bullet_sound_sq2 ;pointer to stream
    .byte $F0           ;tempo..very fast tempo
    
    
enemy_bullet_sound_sq2:
    .byte thirtysecond, C6, G5, E5, C5, G4, E4, C4
    .byte endsound