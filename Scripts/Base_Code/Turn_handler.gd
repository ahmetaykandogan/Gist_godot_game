extends Node2D

enum GamePhase {
	PLAYER_PREPARATION,
	PLAYER_TURN,
	ENEMY_TURN
}

var current_phase = GamePhase.PLAYER_PREPARATION

var spell_used = false

func _on_button_pressed() -> void:   # Combat start button
	if current_phase == GamePhase.PLAYER_PREPARATION and $"CharacterHand".all_characters_placed():
		$"CombatStartButton".hide()
		start_player_turn()
		$SpellHand.draw_a_card()
		$SpellHand.draw_a_card()


func _on_end_turn_pressed() -> void:   # new End turn button
	if current_phase == GamePhase.PLAYER_TURN:
		end_player_turn()

func start_player_turn():
	$SpellHand.draw_a_card()
	print("Something happened!")
	current_phase = GamePhase.PLAYER_TURN
	spell_used = false
	for c in get_tree().get_nodes_in_group("characters"):
		c.set_acted(false)
	$"EndTurnButton".show()

func end_player_turn():
	print("Something happened!")
	current_phase = GamePhase.ENEMY_TURN
	$"EndTurnButton".hide()
	$"SkillTable".hide()
	await $"EnemyManager".run_enemy_turn()
	start_player_turn()
