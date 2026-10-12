class_name HealEffect
extends SkillEffect
 
@export var amount: int = 1
 
func apply(target, _source = null) -> void:
	target.heal(amount)
