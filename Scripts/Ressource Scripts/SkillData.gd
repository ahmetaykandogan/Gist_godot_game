class_name SkillData
extends Resource

@export var skill_name: String
@export var description: String
@export var texture: Texture2D
@export var effects: Array[SkillEffect] = []
@export var target_pattern: TargetPattern
@export var cast_time: int = 1
