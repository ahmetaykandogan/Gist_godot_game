class_name MoveEffect
extends SkillEffect
enum Directions { UP, DOWN, BACK, FRONT }

@export var amount: int = 1
@export var direction: Directions = Directions.BACK

func apply(_target, _source = null) -> void:
	pass
	
