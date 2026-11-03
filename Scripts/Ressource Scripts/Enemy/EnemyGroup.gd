class_name EnemyGroup
extends Resource
## A subgroup of enemies that work well together. One group is chosen per encounter.

@export var group_name: String = ""
@export var enemies: Array[EnemyData] = []     # what can appear (put an enemy twice to make it more likely)
@export var boss: EnemyData                    # optional: arrives on the boss wave
