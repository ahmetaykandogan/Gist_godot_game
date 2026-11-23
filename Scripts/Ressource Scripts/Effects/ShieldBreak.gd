class_name ShieldBreakEffect
extends SkillEffect

func apply(target, _source = null) -> void:
	if is_instance_valid(target) and not target.dying:
		target.remove_status("Shield")
