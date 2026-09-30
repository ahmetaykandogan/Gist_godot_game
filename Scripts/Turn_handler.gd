extends Node2D

enum GamePhase {
	PLAYER_PREPARATION,
	PLAYER_TURN,
	ENEMY_TURN
}

var current_phase = GamePhase.PLAYER_PREPARATION

	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	if current_phase == GamePhase.PLAYER_PREPARATION && $"CharacterHand".all_characters_placed():
		current_phase = GamePhase.PLAYER_TURN
	if current_phase == GamePhase.PLAYER_TURN:
		current_phase = GamePhase.ENEMY_TURN
