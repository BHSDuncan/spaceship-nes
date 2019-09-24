bullet_sound_header:
	.byte $01           ;1 stream
    
    .byte SFX_1         ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte NOISE      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_drum_decay  ;volume envelope
    .word bullet_sound_noise ;pointer to stream
    .byte $50           ;tempo..very fast tempo
    
    
bullet_sound_noise:
    .byte eighth, $04
    .byte endsound