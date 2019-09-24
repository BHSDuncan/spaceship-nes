MAIN_SONG_IDX = $00
SOUND_EXPLOSION_IDX = $01
SOUND_BULLET_IDX = $02
SOUND_ENEMY_BULLET_IDX = $03

song_headers:
	.word   main_song_header
	.word	explosion_sound_header
	.word	bullet_sound_header
	.word	enemy_bullet_sound_header