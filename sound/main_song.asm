main_song_header:
    .byte $04           ;4 streams
    
    .byte MUSIC_SQ1     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_1      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_tgl_1      ;volume envelope
    .word main_song_square1 ;pointer to stream
    .byte $63           ;tempo
    
    .byte MUSIC_SQ2     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte SQUARE_2      ;which channel
    .byte $70           ;initial duty (01)
    .byte ve_pm_1      ;volume envelope
    .word main_song_square2 ;pointer to stream
    .byte $63           ;tempo
    
    .byte MUSIC_TRI     ;which stream
    .byte $01           ;status byte (stream enabled)
    .byte TRIANGLE      ;which channel
    .byte $80           ;initial volume (on)
    .byte ve_battlekid_2      ;volume envelope
    .word main_song_tri     ;pointer to stream
    .byte $63           ;tempo
    
    .byte MUSIC_NOI     ;which stream
    .byte $01           ;status byte: enabled
    .byte NOISE         ;which channel
    .byte $30           ;initial volume_duty value (disable length counter and saw envelope)
    .byte ve_drum_decay ;volume envelope
    .word main_song_noise   ;pointer to the sound data stream
    .byte $63           ;tempo

main_song_square1:
	.byte eighth
	.byte set_loop1_counter, 4
@loopEm:
	.byte E2, B2, E3, G3
	.byte loop1
	.word @loopEm
	.byte set_loop1_counter, 4
@loopEmG:
	.byte G2, B2, D3, G3
	.byte loop1
	.word @loopEmG
	.byte set_loop1_counter, 4
@loopCm:
	.byte C3, E3, G3, B3
	.byte loop1
	.word @loopCm
	.byte set_loop1_counter, 3
@loopAm:
	.byte A2, E3, A3, C4
	.byte loop1
	.word @loopAm
	
	.byte A2, E3, C4, B3
	
	.byte loop
	.word main_song_square1

main_song_square2:
	.byte whole
	.byte set_loop1_counter, 8
@loopIntro:
	.byte rest
	.byte loop1
	.word @loopIntro

	.byte eighth
@loopMelodyStart:
	.byte set_loop1_counter, 6
@loopMain:
	.byte B5, B5, G5, G5, E5, E5, D5, D5
	.byte loop1
	.word @loopMain

	.byte Db4, Db4, Db4, Db4, Db4, Db4, Db4, Db4, Db4, Db4, Db4, Db4, E4, B4
	.byte quarter, G4
	;.byte eighth	

	; scale
	.byte set_loop1_counter, 12
@scale:
	.byte sixteenth, G5, Fs5, E5, D5
	.byte C5, B4, A4, G4
	.byte loop1
	.word @scale

	.byte sixteenth, G5, Fs5, E5, D5
	.byte C5, B4, A4, G4
	.byte Fs4, E4, D4, C4
	.byte B3, A3, G3
	.byte A3, B3, C4, D4
	.byte E4, Fs4, G4, A4
	.byte B4, C5, D5, E5, Fs5
	
	.byte eighth, G5
	.byte rest
	
	.byte loop
	.word @loopMelodyStart

main_song_tri:
	.byte eighth
	.byte set_loop1_counter, 4
@loopEm:
	.byte E3, E3, E3, E3
	.byte loop1
	.word @loopEm
	.byte set_loop1_counter, 4
@loopEmG:
	.byte G3, G3, G3, G3
	.byte loop1
	.word @loopEmG
	.byte set_loop1_counter, 4
@loopCm:
	.byte C4, C4, C4, C4
	.byte loop1
	.word @loopCm
	.byte set_loop1_counter, 4
@loopAm:
	.byte A3, A3, A3, A3
	.byte loop1
	.word @loopAm
	
	.byte loop
	.word main_song_tri

main_song_noise:
	.byte set_loop1_counter, 7
@loopMain:
	.byte quarter, $1F, $1C
	.byte eighth, $1F, $1F
	.byte quarter, $1C
	.byte loop1
	.word @loopMain
	.byte quarter, $1F, $1C
	.byte eighth, $1F, $1F, $1F, $1C	
	.byte loop
	.word main_song_noise