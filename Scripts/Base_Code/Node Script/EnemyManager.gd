extends Node2D
## Brings enemies onto the battlefield in waves.

@export var groups: Array[EnemyGroup] = []     # one group is chosen per encounter, only its enemies appear
@export var enemy_pool: Array[EnemyData] = []  # used only when no group is set
@export var boss_wave: int = 3                 # the wave in which the boss arrives (needs a boss in the group)
@export var boss_with_escorts: bool = true     # true: the boss comes with a normal wave. false: the boss comes alone
@export var wave_interval: int = 3             # initial value of the counter, in turns
@export var wave_size_min: int = 1             # enemies added per wave (random between min and max)
@export var wave_size_max: int = 3

const enemy_scene = preload("res://Scenes/Enemies.tscn")   # keep your own path here
@onready var slot_manager = $"../SlotManager"
@onready var counter_label = $"../WaveCounter"
@onready var passive_manager = get_node_or_null("../PassiveManager")   # registers the auras of arriving enemies

var active_group: EnemyGroup                   # the group chosen for this encounter
var wave_number := 0
var counter := 0
var _boss_pending := false                     # the boss is due but the enemy side was full

func _ready() -> void:
	start_encounter()

# Chooses the group of this encounter and spawns the first wave.
func start_encounter() -> void:
	active_group = groups.pick_random() if not groups.is_empty() else null
	wave_number = 0
	_boss_pending = false
	counter = wave_interval
	spawn_wave()                                 # first wave, visible during preparation
	_update_counter_label()


# ================================== WAVES =====================================
func spawn_wave() -> void:
	wave_number += 1
	var free := _free_slot_count()
	var batch: Array[EnemyData] = []
	if _boss_due() and free > 0:
		batch.append(active_group.boss)          # the boss always gets a place: escorts are cut to fit
		_boss_pending = false
		free -= 1
	elif _boss_due():
		_boss_pending = true                     # no room yet: it arrives as soon as there is some
	if batch.is_empty() or boss_with_escorts:
		batch.append_array(_random_picks(free))
	spawn_batch(batch)

func _boss_due() -> bool:
	return active_group != null and active_group.boss != null and (wave_number == boss_wave or _boss_pending)

func _random_picks(max_count: int) -> Array[EnemyData]:
	var picks: Array[EnemyData] = []
	var pool: Array[EnemyData] = active_group.enemies if active_group else enemy_pool
	if pool.is_empty():
		return picks
	for i in mini(randi_range(wave_size_min, wave_size_max), max_count):
		picks.append(pool.pick_random())         # picked with replacement: 2 mages + 1 healer is possible
	return picks

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
	if passive_manager:
		passive_manager.unit_entered(enemy)                              # its auras become active
	return true

func _free_slot_count() -> int:
	var n := 0
	for row in range(slot_manager.Row_depth):
		for col in slot_manager.side_columns(false):
			if not slot_manager.get_slot(row, col).full:
				n += 1
	return n


# ============================== ENEMY TURN ====================================
func run_enemy_turn() -> void:
	# Phase 1: every enemy chooses an action
	for enemy in get_children():
		if is_instance_valid(enemy) and not enemy.dying:
			enemy.choose_action()
			await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(0.3).timeout           # the player reads all the counters
	# Phase 2: every charging enemy ticks (and fires at 0)
	for enemy in get_children():
		if is_instance_valid(enemy) and not enemy.dying and enemy.pending_skill:
			await enemy.tick_cast()
			await get_tree().create_timer(0.4).timeout

func tick_wave_counter() -> void:                # call once at the end of every enemy turn
	counter -= 1
	_update_counter_label()
	if counter <= 0:
		await get_tree().create_timer(0.4).timeout   # let the player see the 0
		counter = wave_interval
		spawn_wave()
		_update_counter_label()

func _update_counter_label() -> void:
	var text := "Next wave: %d" % counter
	if active_group and active_group.boss and (wave_number + 1 == boss_wave or _boss_pending):
		text += "  (BOSS)"
	counter_label.text = text
