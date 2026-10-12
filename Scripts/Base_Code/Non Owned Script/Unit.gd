class_name Unit
extends Node2D
## Base class of characters and enemies: health, statuses, damage pipeline, skills.

@onready var health_bar = $HealthBar
@onready var slot_manager = $"../../SlotManager"

var skills: Array[SkillData] = []
var health: int
var max_health: int
var slot                          # the slot this unit stands in (null while in hand)
var statuses := {}                # status name -> stacks
var dying := false
var pending_skill: SkillData      # skill being charged (cast box)
var turns_left := 0
var _dealt_damage := false        # did the skill in progress deal damage? (spends Fury)


# =============================== STATUSES ====================================
func get_stacks(status: String) -> int:
	return statuses.get(status, 0)

func add_status(status: String, stacks: int = 1) -> void:
	statuses[status] = get_stacks(status) + stacks

func consume_status(status: String, stacks: int = 1) -> bool:   # true if the status was active
	var left := get_stacks(status) - stacks
	if get_stacks(status) <= 0:
		return false
	if left > 0:
		statuses[status] = left
	else:
		statuses.erase(status)
	return true


# ============================= DAMAGE PIPELINE ================================
# deal_damage()  ->  attacker modifiers  ->  defender modifiers  ->  health loss  ->  reactions
# Flat bonuses are applied by the attacker first, multipliers by the defender after.

func deal_damage(target, base: int, reflected: bool = false) -> void:
	if not is_instance_valid(target) or target.dying:
		return
	var hit := Hit.new(self, target, base, reflected)
	if not reflected:
		_modify_outgoing(hit)
		_dealt_damage = true
	target._receive_hit(hit)

func _modify_outgoing(hit: Hit) -> void:
	# Fury: every hit of the attack deals +1 per stack (stacks are spent after the whole skill)
	hit.amount += get_stacks("Fury")
	# add attacker buffs/debuffs here (Weak, Strength...)

func _modify_incoming(hit: Hit) -> void:
	# Curse: the next hit taken is doubled (one stack per hit)
	if consume_status("Curse"):
		hit.amount *= 2
	# add defender buffs/debuffs here (Shield, Vulnerable...)
	hit.amount = maxi(hit.amount, 0)

func _receive_hit(hit: Hit) -> void:
	_modify_incoming(hit)
	health = maxi(health - hit.amount, 0)
	update_health_bar()
	_react_to_hit(hit)
	if health <= 0:
		die()

func _react_to_hit(hit: Hit) -> void:
	# Spike: whoever attacks us takes damage back (a reflected hit never triggers Spike again)
	var spikes := get_stacks("Spike")
	if spikes > 0 and not hit.reflected and is_instance_valid(hit.source) and hit.source != self:
		deal_damage(hit.source, spikes, true)

func lose_health(amount: int) -> void:
	# Direct loss (bleed, skill costs...): ignores modifiers and reactions
	health = maxi(health - amount, 0)
	update_health_bar()
	if health <= 0:
		die()

func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	update_health_bar()

func update_health_bar() -> void:
	health_bar.value = health
	$HealthBar/Label.text = str(health) + "/" + str(max_health)

func die() -> void:
	if dying:
		return
	dying = true
	if slot:
		var lane = slot.row
		var ally_side = slot_manager.is_ally_slot(slot)
		slot.character = null          # clear first so nothing can target it
		slot.full = false
		slot_manager.compact_lane(lane, ally_side)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()


# ================================== SKILLS ====================================
func use_skill(skill: SkillData) -> void:
	_dealt_damage = false
	for effect in skill.effects:
		if dying:
			return
		@warning_ignore("redundant_await")
		await effect.execute(self, skill.target_pattern, slot_manager)
	if _dealt_damage:
		statuses.erase("Fury")         # Fury is spent once, after every hit of the skill

func begin_cast(skill: SkillData) -> void:
	if skill.cast_time <= 0:
		use_skill(skill)               # instant skill
		return
	pending_skill = skill
	turns_left = skill.cast_time
	update_cast_box()

func tick_cast() -> void:              # called at the end of the owner's turn
	if not pending_skill or dying:
		return
	turns_left -= 1
	update_cast_box()
	if turns_left <= 0:
		await get_tree().create_timer(0.4).timeout
		var skill = pending_skill
		pending_skill = null
		update_cast_box()
		await use_skill(skill)

func update_cast_box() -> void:
	$CastBox.visible = pending_skill != null
	if pending_skill:
		$CastBox/Label.text = str(turns_left)


# ================================== VISUALS ===================================
func setup_sprite(texture: Texture2D) -> void:
	var sprite = $Area2D/Sprite2D
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_size = texture.get_size()
	sprite.scale = Vector2.ONE * min(Layout.CARD_SIZE.x / tex_size.x, Layout.CARD_SIZE.y / tex_size.y)
	var shape = RectangleShape2D.new()
	shape.size = Layout.CARD_SIZE
	$Area2D/CollisionShape2D.shape = shape
	health_bar.position.y = Layout.CARD_SIZE.y / 2 + 6
