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
var description = ""
signal statuses_changed           # emitted whenever a status is added, consumed or removed
@onready var passive_manager = get_node_or_null("../../PassiveManager")
var auras: Array[Aura] = []       # the auras this unit owns

# =============================== STATUSES ====================================
func get_stacks(status: String) -> int:
	return statuses.get(status, 0)

func add_status(status: String, stacks: int = 1) -> void:
	statuses[status] = get_stacks(status) + stacks
	_notify_statuses()

func consume_status(status: String, stacks: int = 1) -> bool:   # true if the status was active
	var left := get_stacks(status) - stacks
	if get_stacks(status) <= 0:
		return false
	if left > 0:
		statuses[status] = left
	else:
		statuses.erase(status)
	_notify_statuses()
	return true

func remove_status(status: String) -> void:       # removes every stack
	if statuses.erase(status):
		_notify_statuses()

func _notify_statuses() -> void:
	statuses_changed.emit()
	update_damage_box()

# ============================= DAMAGE PIPELINE ================================
# deal_damage()  ->  attacker modifiers (Fury, auras)  ->  defender modifiers  ->  health loss  ->  reactions
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
	hit.amount += get_stacks("Fury")
	_modify_by_aura(hit)
	# add attacker buffs/debuffs here (Weak, Strength...)

# The damage this unit would deal for a base value, before any target is known (shown on the card).
# It runs the very same steps as a real hit, so the card always matches what happens.
func outgoing_damage(base: int) -> int:
	var preview := Hit.new(self, null, base)
	_modify_outgoing(preview)
	return preview.amount

func _modify_by_aura(hit: Hit) -> void:
	if passive_manager:
		passive_manager.modify(hit)

func _modify_incoming(hit: Hit) -> void:
	# Curse: the next hit taken is doubled (one stack per hit)
	if consume_status("Curse"):
		hit.amount *= 2
	# add defender buffs/debuffs here (Shield, Vulnerable...)
	var shield := get_stacks("Shield")
	if consume_status("Shield", hit.amount):
		hit.amount -= shield
		if hit.amount<0:
			hit.amount=0
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
	if passive_manager:
		passive_manager.unit_left(self)    # its auras stop applying
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
		var pattern = effect.target_pattern if effect.target_pattern else skill.target_pattern
		if not pattern:
			push_warning(skill.skill_name + ": an effect has no target pattern")
			continue
		@warning_ignore("redundant_await")
		await effect.execute(self, pattern, slot_manager)
	if _dealt_damage:
		remove_status("Fury")
	update_damage_box()

func begin_cast(skill: SkillData) -> void:
	if skill.cast_time <= 0:
		use_skill(skill)
		return
	pending_skill = skill
	turns_left = skill.cast_time
	description = skill.description
	update_cast_box()
	update_damage_box()
	$"Description Box".visible = true

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
		$"Description Box".visible = false
		await use_skill(skill)

func update_cast_box() -> void:
	$CastBox.visible = pending_skill != null
	if pending_skill:
		$CastBox/Label.text = str(turns_left)
	$"Description Box"/Label.text = description

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

func damage_text(skill: SkillData) -> String:
	var parts: Array[String] = []
	for effect in skill.effects:
		var preview: Array = effect.preview_damage(self)
		if preview.is_empty():
			continue
		parts.append(str(preview[0]) if preview[1] <= 1 else "%d*%d" % [preview[0], preview[1]])
	return " + ".join(parts)

func update_damage_box() -> void:
	var text := damage_text(pending_skill) if pending_skill else ""
	if text == "":
		$"Damage Box".visible = false
		return
	$"Damage Box".visible = true
	$"Damage Box"/"Damage Label".text = text
