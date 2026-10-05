class_name StatusEffect
extends SpellEffect

@export var status: String
@export var stacks: int = 1

func apply(target):
	target.add_status(status, stacks)
