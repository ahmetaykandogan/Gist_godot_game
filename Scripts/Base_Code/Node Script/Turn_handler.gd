extends Node2D

enum GamePhase {
	PLAYER_PREPARATION,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY
}

var current_phase = GamePhase.PLAYER_PREPARATION

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
		if is_instance_valid(c) and not c.dying and c.pending_skill:
			await c.tick_statuses()
			await c.tick_cast()
			await get_tree().create_timer(0.1).timeout
	await $"EnemyManager".run_enemy_turn()
	$"EnemyManager".tick_wave_counter()
	if check_victory():
		return
	start_player_turn()

func check_victory() -> bool:
	if current_phase == GamePhase.VICTORY:
		return true
	if $"EnemyManager".is_cleared():
		print("entered")
		current_phase = GamePhase.VICTORY
		$"EndTurnButton".hide()
		$"SkillTable".hide()
		$"VictoryScreen".show()
		return true
	return false
