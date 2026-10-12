class_name SelfBarrageTarget
extends TargetPattern
## Your entire lane (allies in the user's row, the user included).

func get_targets(user, slots) -> Array:
	if not user.slot:
		return []
	return slots.units_in_lane(user.slot.row, slots.is_ally_slot(user.slot))
