class_name DamageEffect
extends SpellEffect

@export var amount: int
func apply(target): 
	target.take_damage(amount)
