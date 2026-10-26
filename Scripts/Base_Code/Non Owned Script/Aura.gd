class_name Aura
extends Resource
## A passive that, while its owner is on the battlefield, changes the damage of a whole side.
## Examples: "all allies deal +1 damage", "enemies take 50% more damage".

enum Affects { CHARACTERS, ENEMIES }
enum Stat { DAMAGE_DEALT }
enum Mode { ADD, MULTIPLY }

@export var aura_name: String = ""
@export_multiline var description: String = ""
@export var affects: Affects = Affects.CHARACTERS
@export var include_self: bool = true 
@export var stat: Stat = Stat.DAMAGE_DEALT
@export var mode: Mode = Mode.ADD
@export var value: int = 1
