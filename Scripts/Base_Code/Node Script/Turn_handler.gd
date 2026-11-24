extends Node2D

enum GamePhase {
	PLAYER_PREPARATION,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

const VICTORY_SCENE := preload("res://Scenes/Victory.tscn")
const DEFEAT_SCENE := preload("res://Scenes/Defeat.tscn")

var current_phase = GamePhase.PLAYER_PREPARATION

# The end of the battle can happen at any moment (a hit, a reflected Spike, a bleed...),
# so it is watched every frame, using the units' own "dying" flag set by Unit.die().
func _process(_delta: float) -> void:
	if current_phase != GamePhase.PLAYER_TURN and current_phase != GamePhase.ENEMY_TURN:
		return
	if party_wiped_out():
		end_battle(GamePhase.DEFEAT)
	elif $"EnemyManager".is_cleared():       # boss wave arrived and no enemy is left
		end_battle(GamePhase.VICTORY)

func _on_button_pressed() -> void:   # Combat start button
	if current_phase == GamePhase.PLAYER_PREPARATION and $"CharacterHand".all_characters_placed():
		$"CombatStartButton".hide()
		start_player_turn()

func _on_end_turn_pressed() -> void:
	if current_phase == GamePhase.PLAYER_TURN:
		end_player_turn()

func start_player_turn():
	current_phase = GamePhase.PLAYER_TURN
	for c in get_tree().get_nodes_in_group("characters"):
		c.set_acted(c.pending_skill != null)
		c.moves_left = c.MOVES_PER_TURN
	$"EndTurnButton".show()

func end_player_turn():
	for c in get_tree().get_nodes_in_group("characters"):
		if is_instance_valid(c) and not c.dying and c.pending_skill == null:
			print("A character has no chosen skill!")
			return
	current_phase = GamePhase.ENEMY_TURN
	$"EndTurnButton".hide()
	$"SkillTable".hide()
	for c in get_tree().get_nodes_in_group("characters"):
		if battle_over():
			return
		if is_instance_valid(c) and not c.dying and c.pending_skill:
			await c.tick_statuses()
			await c.tick_cast()
			await get_tree().create_timer(0.1).timeout
	if battle_over():
		return
	await $"EnemyManager".run_enemy_turn()
	if battle_over():
		return
	$"EnemyManager".tick_wave_counter()
	if battle_over():
		return
	start_player_turn()

func check_victory() -> bool:
	if current_phase == GamePhase.VICTORY:
		return true
	if $"EnemyManager".is_cleared():
		end_battle(GamePhase.VICTORY)
		return true
	return false

func battle_over() -> bool:
	return current_phase == GamePhase.VICTORY or current_phase == GamePhase.DEFEAT

func party_wiped_out() -> bool:
	for c in get_tree().get_nodes_in_group("characters"):
		if is_instance_valid(c) and not c.dying:
			return false
	return true

# The only place that shows an end screen. The phase is set first, so a second call
# (from _process, check_victory or the turn flow) does nothing.
func end_battle(result: GamePhase) -> void:
	if battle_over():
		return
	current_phase = result
	$"EndTurnButton".hide()
	$"SkillTable".hide()
	var screen: PackedScene = VICTORY_SCENE if result == GamePhase.VICTORY else DEFEAT_SCENE
	add_child(screen.instantiate())
