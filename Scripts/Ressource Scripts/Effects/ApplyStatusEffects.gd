class_name ApplyStatusEffect
extends SkillEffect
 
@export var status: String = ""
@export var stacks: int = 1
 
func apply(target, _source = null) -> void:
	target.add_status(status, stacks)
