extends Node2D
## Brings enemies onto the battlefield in waves.

@export var enemy_pool: Array[EnemyData] = []   # what can appear (put an enemy twice to make it more likely)
@export var wave_interval: int = 3              # initial value of the counter, in turns
@export var wave_size_min: int = 1              # enemies added per wave (random between min and max)
@export var wave_size_max: int = 3

const enemy_scene = preload("res://Scenes/Enemies.tscn")   # keep your own path here
@onready var slot_manager = $"../SlotManager"
@onready var counter_label = $"../WaveCounter"
@onready var passive_manager = $"../PassiveManager"
var counter := 0

func _ready() -> void:
	counter = wave_interval
	_update_counter_label()
	spawn_wave()                                 # first wave, visible during preparation


# ================================== WAVES =====================================
func spawn_wave() -> void:
	if enemy_pool.is_empty():
		return
	var chosen: Array[EnemyData] = []
	for i in randi_range(wave_size_min, wave_size_max):
		chosen.append(enemy_pool.pick_random())
	spawn_batch(chosen)

# Highest priority goes closest to the front; the lane of each enemy is random.
func spawn_batch(batch: Array[EnemyData]) -> void:
	batch.shuffle()                                                  # equal priorities keep a random order
	batch.sort_custom(func(a, b): return a.priority > b.priority)
	for data in batch:
		if not _spawn_enemy(data):
			break                                                    # the enemy side is full

func _spawn_enemy(data: EnemyData) -> bool:
	var lanes: Array = []
	for row in range(slot_manager.Row_depth):
		if slot_manager.get_frontmost_free_slot(row, false):
			lanes.append(row)
	if lanes.is_empty():
		return false
	var slot = slot_manager.get_frontmost_free_slot(lanes.pick_random(), false)   # random lane, next spot behind its units
	var enemy = enemy_scene.instantiate()
	enemy.data = data                                                # set BEFORE add_child
	add_child(enemy)
	enemy.global_position = slot.global_position
	slot.character = enemy
	slot.full = true
	enemy.slot = slot
	passive_manager.unit_entered(enemy)
	return true

# ============================== ENEMY TURN ====================================
func run_enemy_turn() -> void:
	# Phase 1: every enemy chooses an action
	for enemy in get_children():
		if is_instance_valid(enemy) and not enemy.dying:
			enemy.choose_action()
			await get_tree().create_timer(0.4).timeout
	await get_tree().create_timer(0.6).timeout           # the player reads all the counters
	# Phase 2: every charging enemy ticks (and fires at 0)
	for enemy in get_children():
		if is_instance_valid(enemy) and not enemy.dying and enemy.pending_skill:
			await enemy.tick_cast()
			await get_tree().create_timer(0.4).timeout

func tick_wave_counter() -> void:                # call once at the end of every enemy turn
	counter -= 1
	_update_counter_label()
	if counter <= 0:
		await get_tree().create_timer(0.6).timeout   # let the player see the 0
		counter = wave_interval
		spawn_wave()
		_update_counter_label()

func _update_counter_label() -> void:
	counter_label.text = "Next wave: %d" % counter
