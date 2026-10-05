extends Node2D

@export var encounter: Array[EnemyData] = []

const enemy_scene = preload("res://Scenes/Enemies.tscn")
@onready var slot_manager = $"../SlotManager"

func _ready() -> void:
	for data in encounter:
		spawn_enemy(data)

func spawn_enemy(data: EnemyData):
	var free_slots = slot_manager.get_free_slots(data.allowed_columns)
	if free_slots.is_empty():
		print("No free slot for ", data.enemy_name)
		return
	var slot = free_slots.pick_random()
	var enemy = enemy_scene.instantiate()
	enemy.data = data
	add_child(enemy)
	enemy.global_position = slot.global_position
	slot.character = enemy
	slot.full = true
	enemy.slot = slot

func run_enemy_turn():

	for enemy in get_children():
		if is_instance_valid(enemy) and not enemy.dying:
			enemy.choose_action()
			await get_tree().create_timer(0.4).timeout

	await get_tree().create_timer(0.6).timeout     # player reads all the numbers
	for enemy in get_children():
		if is_instance_valid(enemy) and not enemy.dying and enemy.pending_skill:
			await enemy.tick_cast()
			await get_tree().create_timer(0.4).timeout
