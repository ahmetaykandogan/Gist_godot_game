class_name DirectionalTarget
extends TargetPattern
## The adjacent ally in one direction (for buffs). Empty if there is nobody or it is off the board.

enum Direction { FRONT, BACK, UP, DOWN }

@export var direction: Direction = Direction.FRONT

func get_targets(user, slots) -> Array:
	if not user.slot:
		return []
	var ally_side: bool = slots.is_ally_slot(user.slot)
	var toward_enemy: int = 1 if ally_side else -1      # column step toward the enemy side
	var row: int = user.slot.row
	var col: int = user.slot.column
	match direction:
		Direction.FRONT:
			col += toward_enemy
		Direction.BACK:
			col -= toward_enemy
		Direction.UP:
			row -= 1
		Direction.DOWN:
			row += 1
	var s = slots.get_slot(row, col)
	if s and slots.is_ally_slot(s) == ally_side and s.character and not s.character.dying:
		return [s.character]
	return []
