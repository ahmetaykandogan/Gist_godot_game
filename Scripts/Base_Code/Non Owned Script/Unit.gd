class_name Unit
extends Node2D

@onready var health_bar = $HealthBar
@onready var slot_manager = $"../../SlotManager"

var skills: Array[SkillData] = []
var health
var max_health: int
var slot   # the slot this unit stands in (null while in hand)
var statuses = {}
var dying = false
var pending_skill: SkillData
var turns_left = 0

func update_health_bar():
	health_bar.value = health
	$HealthBar/Label.text = str(health) + "/" + str(max_health)

func add_status(status_name, stacks):
	statuses[status_name] = statuses.get(status_name, 0) + stacks

func consume_status(status_name):
	if not statuses.has(status_name):
		return false
	statuses[status_name] -= 1
	if statuses[status_name] <= 0:
		statuses.erase(status_name)
	return true

func take_damage(amount):
	if consume_status("Curse"):
		amount *= 2
	health -= amount
	update_health_bar()
	if health <= 0:
		die()

func heal(amount):
	health = min(health + amount, max_health)
	update_health_bar()

func die():
	if dying:
		return
	dying = true
	if slot:
		slot.character = null
		slot.full = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

func use_skill(skill: SkillData):
	for target in skill.target_pattern.get_targets(self, slot_manager):
		if not is_instance_valid(target):
			continue
		for effect in skill.effects:
			effect.apply(target)

const CARD_SIZE = Vector2(150, 200)

func setup_sprite(texture: Texture2D):
	var sprite = $Area2D/Sprite2D
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_size = texture.get_size()
	sprite.scale = Vector2.ONE * min(CARD_SIZE.x / tex_size.x, CARD_SIZE.y / tex_size.y)

func begin_cast(skill: SkillData):
	pending_skill = skill
	turns_left = skill.cast_time
	update_cast_box()

func tick_cast():   
	if not pending_skill or dying:
		return
	turns_left -= 1
	update_cast_box()
	if turns_left <= 0:
		var skill = pending_skill
		pending_skill = null
		update_cast_box()
		use_skill(skill)

func update_cast_box():
	$CastBox.visible = pending_skill != null
	if pending_skill:
		$CastBox/Label.text = str(turns_left)
