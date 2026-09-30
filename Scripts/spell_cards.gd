extends Node2D


signal hovered
signal hovered_ended

var hand_pos
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../../CardManager".connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_ended", self)
