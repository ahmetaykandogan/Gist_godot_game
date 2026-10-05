extends Unit

signal hovered
signal hovered_ended

@export var data: CharacterData
var hand_pos
var has_acted = false

func _ready() -> void:
	add_to_group("characters")
	$"../../CardManager".connect_card_signals(self)
	max_health = data.max_health
	health = max_health
	skills = data.skills
	setup_sprite(data.texture)
	health_bar.max_value = max_health
	update_health_bar()

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_ended", self)
	
func set_acted(value: bool):
	has_acted = value
	$Area2D/Sprite2D.modulate = Color(0.459, 0.355, 0.442, 1.0) if value else Color.WHITE

func try_use_skill(skill):
	if has_acted:
		return
	set_acted(true)
	begin_cast(skill)
