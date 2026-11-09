class_name AudioManager
extends Node
## Plays the game's sounds and music. Sounds can overlap, so quick multi-hit attacks are not cut off.

@export var attack_sound: AudioStream
@export_range(-40.0, 6.0) var attack_volume_db: float = 0.0
@export var attack_polyphony: int = 4            # how many attack sounds can play at once

@export var music_normal: AudioStream            # plays during the encounter
@export var music_boss: AudioStream              # takes over when the boss enters
@export_range(-40.0, 6.0) var music_volume_db: float = -8.0
@export var crossfade_seconds: float = 1.5

var plays := 0                                   # number of attack sounds started (handy for tests)
var current_music: AudioStream
var _attack_player: AudioStreamPlayer
var _last_attack_frame := -1
var _music_players: Array[AudioStreamPlayer] = []
var _music_active := 0

func _ready() -> void:
	_attack_player = AudioStreamPlayer.new()
	_attack_player.stream = attack_sound
	_attack_player.volume_db = attack_volume_db
	_attack_player.max_polyphony = attack_polyphony
	add_child(_attack_player)
	for i in 2:                                  # two players, to crossfade between tracks
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_music_players.append(p)
	play_normal_music(0.0)


# =================================== SOUNDS ===================================
# One sound per hit. Several targets hit on the same frame (a barrage) count as ONE hit.
func play_attack() -> void:
	if attack_sound == null:
		return
	var frame := Engine.get_process_frames()
	if frame == _last_attack_frame:
		return
	_last_attack_frame = frame
	plays += 1
	_attack_player.play()


# =================================== MUSIC ====================================
func play_normal_music(fade: float = -1.0) -> void:
	_play_music(music_normal, fade)

func boss_entered() -> void:                     # call when the boss arrives
	_play_music(music_boss, -1.0)

func _play_music(stream: AudioStream, fade: float) -> void:
	if stream == null or stream == current_music:
		return                                   # nothing to play, or already playing
	if fade < 0.0:
		fade = crossfade_seconds
	current_music = stream
	if "loop" in stream:
		stream.loop = true                       # ogg and mp3 music loops
	var old := _music_players[_music_active]
	_music_active = 1 - _music_active
	var new_player := _music_players[_music_active]
	new_player.stream = stream
	new_player.volume_db = -80.0 if fade > 0.0 else music_volume_db
	new_player.play()
	if fade <= 0.0:
		old.stop()
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(new_player, "volume_db", music_volume_db, fade)
	if old.playing:
		tween.tween_property(old, "volume_db", -80.0, fade)
		tween.chain().tween_callback(old.stop)
