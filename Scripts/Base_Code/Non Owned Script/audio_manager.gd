class_name AudioManager
extends Node
## Plays the game's sounds and music. Sounds can overlap, so quick multi-hit attacks are not cut off.

@export var attack_sound: AudioStream
@export_range(-40.0, 6.0) var attack_volume_db: float = 0.0
@export var attack_polyphony: int = 4            # how many attack sounds can play at once

@export var select_sound: AudioStream            # played when the player selects a skill
@export_range(-40.0, 6.0) var select_volume_db: float = 0.0

@export var music_normal: AudioStream            # plays during the encounter
@export var music_boss: AudioStream              # takes over when the boss enters
@export_range(-40.0, 6.0) var music_volume_db: float = -8.0
@export var crossfade_seconds: float = 1.5

var plays := 0                                   # attack sounds started (handy for tests)
var select_plays := 0                            # selection sounds started
var current_music: AudioStream
var _attack_player: AudioStreamPlayer
var _select_player: AudioStreamPlayer
var _last_attack_frame := -1
var _music_players: Array[AudioStreamPlayer] = []
var _music_active := 0
var _ready_done := false
var _pending_music: AudioStream                  # asked for before the node was ready

func _ready() -> void:
	_ready_done = true
	_attack_player = AudioStreamPlayer.new()
	_attack_player.stream = attack_sound
	_attack_player.volume_db = attack_volume_db
	_attack_player.max_polyphony = attack_polyphony
	add_child(_attack_player)
	_select_player = AudioStreamPlayer.new()
	_select_player.stream = select_sound
	_select_player.volume_db = select_volume_db
	_select_player.max_polyphony = 2
	add_child(_select_player)
	for i in 2:                                  # two players, to crossfade between tracks
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		p.finished.connect(_on_music_finished.bind(p))
		add_child(p)
		_music_players.append(p)
	play_normal_music(0.0)
	if _pending_music != null:                   # e.g. the boss entered before this node was ready
		_play_music(_pending_music, -1.0)
		_pending_music = null


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

# Played when the player selects a skill.
func play_select() -> void:
	if select_sound == null or not _ready_done:
		return
	select_plays += 1
	_select_player.play()


# =================================== MUSIC ====================================
func play_normal_music(fade: float = -1.0) -> void:
	_play_music(music_normal, fade)

func boss_entered() -> void:                     # call when the boss arrives
	if music_boss == null:
		push_warning("AudioManager: boss_entered() was called but no Music Boss is assigned.")
		return
	if music_boss == current_music:
		push_warning("AudioManager: Music Boss is the same file as Music Normal, so nothing changes.")
		return
	print("AudioManager: boss music")
	_play_music(music_boss, -1.0)

func _play_music(stream: AudioStream, fade: float) -> void:
	if stream == null or stream == current_music:
		return                                   # nothing to play, or already playing
	if not _ready_done:
		_pending_music = stream
		return
	if fade < 0.0:
		fade = crossfade_seconds
	current_music = stream
	_enable_loop(stream)
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

# Makes the track repeat. ogg and mp3 have a loop option; wav needs a loop range.
func _enable_loop(stream: AudioStream) -> void:
	if "loop" in stream:
		stream.loop = true
	elif stream is AudioStreamWAV and (stream.format == AudioStreamWAV.FORMAT_8_BITS or stream.format == AudioStreamWAV.FORMAT_16_BITS):
		var bytes := 1 if stream.format == AudioStreamWAV.FORMAT_8_BITS else 2
		if stream.stereo:
			bytes *= 2
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(float(stream.data.size()) / bytes)

# Safety net for any stream that can not loop by itself: when the current track ends, start it again.
func _on_music_finished(player: AudioStreamPlayer) -> void:
	if current_music != null and player == _music_players[_music_active] and player.stream == current_music:
		player.play()
