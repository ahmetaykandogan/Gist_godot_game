class_name PushEffect
extends SkillEffect
## Moves the units it hits. Put it after the damage effect of an attack.
## Directions are relative to each unit's own side: front = toward the enemy, back = away from it.

enum Direction { FRONT, BACK, UP, DOWN }

@export var direction: Direction = Direction.BACK
@export_range(1, 2) var distance: int = 1       # 3 is not possible: a side has only 3 positions

func execute(user, pattern, slots) -> void:
	var targets: Array = pattern.get_targets(user, slots)
	# Several targets: the ones farthest along the push move first.
	var key := {}
	for t in targets:
		var index: int = slots.side_columns(slots.is_ally_slot(t.slot)).find(t.slot.column)
		key[t] = -index if direction == Direction.BACK else index
	if direction == Direction.BACK or direction == Direction.FRONT:
		targets.sort_custom(func(a, b): return key[a] < key[b])
	for t in targets:
		if is_instance_valid(t) and not t.dying and t.slot:
			_push(t, slots, targets)

func apply(target, _source = null) -> void:
	if is_instance_valid(target) and not target.dying and target.slot:
		_push(target, target.slot_manager, [])

# `group` = everyone pushed by this effect: two units of the group never trade places with each other.
func _push(target, slots, group: Array) -> void:
	for i in distance:                          # one step at a time, stopping at the edge of the board
		var moved := false
		match direction:
			Direction.FRONT:
				moved = slots.shift_in_lane(target, -1, group)
			Direction.BACK:
				moved = slots.shift_in_lane(target, 1, group)
			Direction.UP:
				moved = slots.shift_to_lane(target, -1, group)
			Direction.DOWN:
				moved = slots.shift_to_lane(target, 1, group)
		if not moved:
			break
