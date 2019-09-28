TITLE_SONG_IDX = $00
MAIN_SONG_IDX = $01
SOUND_EXPLOSION_IDX = $02
SOUND_BULLET_IDX = $03
SOUND_ENEMY_BULLET_IDX = $04

song_headers:
	.word	title_music_header
	.word   main_song_header
	.word	explosion_sound_header
	.word	bullet_sound_header
	.word	enemy_bullet_sound_header
