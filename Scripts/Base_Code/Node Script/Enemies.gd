extends Unit

@export var data: EnemyData
var hand_pos

func _ready() -> void:
	$"../../CardManager".connect_card_signals(self)
	max_health = data.max_health
	health = max_health
	skills = data.skills
	setup_sprite(data.texture)
	health_bar.max_value = max_health
	update_health_bar()
	
func choose_action():
	if pending_skill or not data.ai:
		return
	var skill = data.ai.choose_skill(self)
	if skill:
		begin_cast(skill)

func take_turn():
	if pending_skill:
		tick_cast()
		return
	if not data.ai:
		return
	var skill = data.ai.choose_skill(self)
	if skill:
		begin_cast(skill)
	
