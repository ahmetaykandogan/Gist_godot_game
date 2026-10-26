class_name EnemyData
extends Resource

@export var enemy_name: String
@export var texture: Texture2D
@export var max_health: int
@export var skills: Array[SkillData] = []
@export var auras: Array[Aura]
@export var priority: int = 0
@export var ai: EnemyAI
