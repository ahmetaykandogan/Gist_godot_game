class_name Hit
extends RefCounted
## One instance of damage travelling from an attacker to a defender.
## Attacker and defender modifiers edit `amount` before it is applied.

var source                    # the attacking Unit (can be null, or freed by now)
var target                    # the defending Unit
var amount: int
var reflected: bool = false   # true for reflected damage (Spike): skips attacker modifiers, can't be reflected again

func _init(p_source, p_target, p_amount: int, p_reflected: bool = false) -> void:
	source = p_source
	target = p_target
	amount = p_amount
	reflected = p_reflected
