extends Node2D

signal hovered
signal hovered_ended

@export var data: SpellData
var hand_pos

func _ready() -> void:
	$"../../SpellManager".connect_card_signals(self)
	if data:
		$Area2D/Sprite2D.texture = data.texture

func cast(target):
	for effect in data.effects:
		effect.apply(target)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_ended", self)
