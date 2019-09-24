explosion_sound_header:
	.byte $01           ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte NOISE      ;which channel
    .byte $B0           ;initial duty (01)
    .byte ve_long_fade_out  ;volume envelope
    .word explosion_sound_noise ;pointer to stream
    .byte $C0           ;tempo..very fast tempo
    
    
explosion_sound_noise:
    .byte thirtysecond, $0C, $0C, $0D, $0D, $0E, $0E, $0F, $0E, $0F, $0F, $0F, $0F, $0F
    .byte endsound