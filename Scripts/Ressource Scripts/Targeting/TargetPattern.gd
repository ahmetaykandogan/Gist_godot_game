class_name TargetPattern
extends Resource
## Base type of targeting styles. get_targets() is asked again before every hit of a multi-hit attack.

func get_targets(_user, _slots) -> Array:
	return []
