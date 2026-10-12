class_name SelfTarget
extends TargetPattern
## Only the user.

func get_targets(user, _slots) -> Array:
	return [user]
