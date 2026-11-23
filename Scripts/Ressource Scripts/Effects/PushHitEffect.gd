class_name PushHitEffect
extends SkillEffect
## Self-contained multi-hit: each hit deals damage, pushes the target 1 step,
## then the push deals extra damage. Targets are re-queried from the pattern on EVERY hit.

enum Direction { FRONT, BACK, UP, DOWN }

@export var amount: int = 1                 # damage of each hit
@export var hit_time: int = 1               # number of hits
@export var hit_delay: float = 0.15         # seconds between hits
@export var direction: Direction = Direction.BACK
@export var push_damage: int = 1            # damage dealt by each push
@export var only_if_moved := true           # true = no push damage if the unit couldn't move

func execute(user, pattern, slots) -> void:
	for i in hit_time:
		if not is_instance_valid(user) or user.dying:
			return
		var targets: Array = pattern.get_targets(user, slots).filter(
			func(t): return is_instance_valid(t) and not t.dying)
		if targets.is_empty():
			return
		# 1. Hit
		for t in targets:
			user.deal_damage(t, amount)
		# 2. Push, farthest units first so they don't block each other
		var key := {}
		for t in targets:
			if t.slot:
				var index: int = slots.side_columns(slots.is_ally_slot(t.slot)).find(t.slot.column)
				key[t] = -index if direction == Direction.BACK else index
		if direction == Direction.BACK or direction == Direction.FRONT:
			targets.sort_custom(func(a, b): return key.get(a, 0) < key.get(b, 0))
		for t in targets:
			if not is_instance_valid(t) or t.dying or not t.slot:
				continue
			var moved := _shift(t, slots, targets)
			# 3. Push damage
			if moved or not only_if_moved:
				user.deal_damage(t, push_damage)
		if i < hit_time - 1:
			await user.get_tree().create_timer(hit_delay).timeout

func _shift(t, slots, group: Array) -> bool:
	match direction:
		Direction.FRONT: return slots.shift_in_lane(t, -1, group)
		Direction.BACK:  return slots.shift_in_lane(t, 1, group)
		Direction.UP:    return slots.shift_to_lane(t, -1, group)
		Direction.DOWN:  return slots.shift_to_lane(t, 1, group)
	return false

# Card display: "damage*hits" (hit + push damage per hit)
func preview_damage(user) -> Array:
	return [user.outgoing_damage(amount) + user.outgoing_damage(push_damage), hit_time]
