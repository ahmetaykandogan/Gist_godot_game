class_name HealEffect
extends SpellEffect


@export var amount: int
func apply(target): 
	target.heal(amount)
