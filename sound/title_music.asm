title_music_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_long_fade_out      ;volume envelope
    .word title_music_square1 ;pointer to stream
    .byte $40           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_long_fade_out      ;volume envelope
    .word title_music_square2 ;pointer to stream
    .byte $40           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $80           ;initial volume (on)
    .byte ve_battlekid_2      ;volume envelope
    .word title_music_tri     ;pointer to stream
    .byte $40           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $01           ;status byte: enabled
    .byte NOISE         ;which channel
    .byte $30           ;initial volume_duty value (disable length counter and saw envelope)
    .byte ve_drum_decay ;volume envelope
    .word title_music_noise   ;pointer to the sound data stream
    .byte $40           ;tempo

title_music_square1:
	.byte set_loop1_counter, 4
	@part1:
	.byte whole, E3
	.byte loop1
	.word @part1

	.byte set_loop1_counter, 4
	@part2:
	.byte whole, C3
	.byte loop1
	.word @part2
		
	.byte loop
	.word title_music_square1

title_music_square2:
	.byte set_loop1_counter, 2
	@part1:
	.byte whole, Gs3, G3
	.byte loop1
	.word @part1
	
	.byte set_loop1_counter, 2
	@part2:
	.byte whole, E3, Eb3
	.byte loop1
	.word @part2
	
	.byte loop
	.word title_music_square2

title_music_tri:
	.byte set_loop1_counter, 4
	@part1:
	.byte eighth
	.byte E3, E3, E3, E3, E5, E3, E3, E3
	.byte loop1
	.word @part1
	
	.byte set_loop1_counter, 2
	@part2:
	.byte sixteenth
	.byte E3, E3, E3, E3
	.byte eighth
	.byte E3, E3, E5, E3, E3, E3
	.byte E3, E3, E3, E3, E5, E3, E3, E3
	.byte loop1
	.word @part2
	
	.byte loop
	.word title_music_tri

title_music_noise:
	.byte quarter, $1F	
	.byte eighth, rest
	.byte $1F
	.byte quarter, $1C
	.byte rest
	.byte loop
	.word title_music_noise