class_name FarShotTargeting
extends TargetPattern

#Character target the first just in front, enemy or ally alike

func get_targets(user, slot_manager):
	var slot = slot_manager.get_last_slot_in_front_target(user.slot)
	print(slot)
	return [slot.character] if slot and slot.character else []
