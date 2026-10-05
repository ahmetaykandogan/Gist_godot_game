class_name FrontTarget
extends TargetPattern
func get_targets(user, slot_manager):
	var slot = slot_manager.get_slot_in_front(user.slot)
	return [slot.character] if slot and slot.character else []
