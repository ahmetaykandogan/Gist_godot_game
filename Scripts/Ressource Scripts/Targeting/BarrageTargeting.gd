class_name BarrageTarget
extends TargetPattern
## The entire enemy lane (own lane first; if it is empty, the nearest lane with enemies).

func get_targets(user, slots) -> Array:
	if not user.slot:
		return []
	var their_side: bool = not slots.is_ally_slot(user.slot)
	for lane in slots.lanes_by_distance(user.slot.row):
		var units: Array = slots.units_in_lane(lane, their_side)
		if not units.is_empty():
			return units
	return []
