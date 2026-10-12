class_name NormalTargeting
extends TargetPattern
## The first enemy in front. If the lane is empty, the nearest lane with an enemy.

func get_targets(user, slots) -> Array:
	if not user.slot:
		return []
	var their_side: bool = not slots.is_ally_slot(user.slot)   # true = the enemy side is columns 0-2
	for lane in slots.lanes_by_distance(user.slot.row):
		var units: Array = slots.units_in_lane(lane, their_side)
		if not units.is_empty():
			return [units[0]]
	return []
