class_name PassiveManager
extends Node
## Keeps the list of the auras that are active right now, one list per side.
## A unit registers its auras when it arrives on the battlefield and removes them when it dies or leaves.

class ActiveAura:
	var owner_unit
	var aura: Aura
	func _init(p_unit, p_aura: Aura) -> void:
		owner_unit = p_unit
		aura = p_aura

@onready var slot_manager = $"../SlotManager"

var ally_auras: Array[ActiveAura] = []      # auras that affect characters
var enemy_auras: Array[ActiveAura] = []     # auras that affect enemies
var _refresh_queued := false


# ============================ REGISTERING AURAS ===============================
# Call when a unit arrives on the battlefield (its slot must already be set).
func unit_entered(unit) -> void:
	#unit_left(unit)
	if not unit.slot or unit.auras.is_empty():
		return
	for aura in unit.auras:
		if aura.affects == Aura.Affects.CHARACTERS:
			ally_auras.append(ActiveAura.new(unit, aura))
		else:
			enemy_auras.append(ActiveAura.new(unit, aura))
	_changed()

# Call when a unit dies or is taken off the battlefield.
func unit_left(unit) -> void:
	var removed := _remove_from(ally_auras, unit)
	removed = _remove_from(enemy_auras, unit) or removed
	if removed:
		_changed()

func _remove_from(list: Array[ActiveAura], unit) -> bool:
	var removed := false
	for i in range(list.size() - 1, -1, -1):          # backwards, so removing does not skip entries
		if list[i].owner_unit == unit:
			list.remove_at(i)
			removed = true
	return removed


# ============================== MODIFYING DAMAGE ==============================
# Changes hit.amount using every active aura that affects the attacker's side.
# Flat bonuses are added first, then the multipliers are applied.
func modify(hit: Hit) -> void:
	var source = hit.source
	if not is_instance_valid(source) or not source.slot:
		return                                   # not on the battlefield: no aura
	var acc := {"flat": 0.0, "mult": 1.0}
	if slot_manager.is_ally_slot(source.slot):   # a character is attacking
		_apply(acc, ally_auras)
	else:                                        # an enemy is attacking
		_apply(acc, enemy_auras)
	hit.amount = maxi(roundi((hit.amount + acc.flat) * acc.mult), 0)

func _apply(acc: Dictionary, list: Array[ActiveAura]) -> void:
	for entry in list:
		if entry.aura.mode == Aura.Mode.ADD:
			acc.flat += entry.aura.value
		elif entry.aura.mode == Aura.Mode.MULTIPLY:
			acc.mult *= entry.aura.value


# ================================ CARD REFRESH ================================
# Auras changed the numbers on the cards (Damage Box): refresh them once, after the whole batch of changes.
func _changed() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh_cards.call_deferred()

func _refresh_cards() -> void:
	_refresh_queued = false
	for row in slot_manager.character_slots:
		for s in row:
			if s.character and is_instance_valid(s.character):
				s.character.update_damage_box()
