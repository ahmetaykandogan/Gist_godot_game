class_name EnemyData
extends Resource

@export var enemy_name: String
@export var texture: Texture2D
@export var max_health: int
@export var skills: Array[SkillData] = []
@export var allowed_columns: Array[int]
@export var ai: EnemyAI
