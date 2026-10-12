extends Node2D

var Row_length = 6 #The actual game will have double, for enemy side too
var Row_depth = 2

const character_slot_scene_path = "res://Scenes/Character_slot.tscn"
const hand_y_position = 850
const card_width = 200
var center_screen_x

var character_slots = [[],[]]
# Called when the node enters the scene tree for the first time.
#Add all the cards when the game starts
func _ready() -> void:
	for i in range(Row_depth):
		for j in range(Row_length):
			character_slots[i].append(null)
	var slot_scene = preload(character_slot_scene_path)
	for i in range(Row_depth): #We put the required slot on the line
		for j in range(Row_length): #We put the required slot on the depth
			var new_slot = slot_scene.instantiate()
			add_child(new_slot)
			new_slot.name = "Slot"
			new_slot.row = i
			new_slot.column = j
			add_slot_to_board(new_slot, i, j)

func add_slot_to_board(new_slot, i, j): #adds a slot to [j][i]
	character_slots[i][j] = new_slot
	update_slot_position(new_slot, i, j)
	
func update_slot_position(slot, row, column):
	slot.position = Layout.BOARD_ORIGIN + Vector2(column, row) * Layout.SLOT_STEP

#------------------------------Targetting---------------------------------------------

func get_slot(row, column):
	if row < 0 or row >= Row_depth or column < 0 or column >= Row_length:
		return null   # outside the board
	return character_slots[row][column]

# The slot directly next to this one, toward the enemy side
func get_slot_in_front_direct(slot):
	var direction
	if slot.column <= 2:  
		direction = 1
	else:
		direction = -1
	return character_slots[slot.row][slot.column + direction]

#Basic identifier of who is gonna be targeted
func get_slot_in_front_target(slot):
	if slot.column <= 2:  
		if character_slots[slot.row][3].full == false:
			if slot.row == 0:
				return character_slots[1][3]
			else:
				return character_slots[0][3]
		return character_slots[slot.row][3]
	else:
		if character_slots[slot.row][2].full == false:
			if slot.row == 0:
				return character_slots[1][2]
			else:
				return character_slots[0][2]
		return character_slots[slot.row][2]

	
func get_first_target_in_row(slot):
	var direction = 1 if slot.column <= 2 else -1
	var column = slot.column + direction
	while column >= 0 and column < Row_length:
		var s = get_slot(slot.row, column)
		if s.character:
			return s
		column += direction
	return null

func get_all_slots_in_row(slot): #To hit everything in row
	return character_slots[slot.row].duplicate()

func get_free_slots(columns: Array) -> Array:
	var result = []
	for row in character_slots:
		for s in row:
			if s.column in columns and not s.full:
				result.append(s)
	return result
	
	
# True if the slot is on the ally side (columns 0-2)
func is_ally_slot(slot) -> bool:
	return slot.column < SIDE_SIZE
 
# Living units of one lane on one side, ordered FRONT -> BACK.
# ally_side = true means the side made of columns 0-2.
func units_in_lane(row: int, ally_side: bool) -> Array:
	var result = []
	for col in side_columns(ally_side):
		var s = get_slot(row, col)
		if s and s.character and not s.character.dying:
			result.append(s.character)
	return result
 
# Lane indexes sorted by distance to `row`: [own lane, nearest lane, ...]
func lanes_by_distance(row: int) -> Array:
	var lanes = range(Row_depth)
	lanes.sort_custom(func(a, b):
		var da = abs(a - row)
		var db = abs(b - row)
		return da < db or (da == db and a < b))
	return lanes
#----------------------------------------------Compression code-----------------------

const SIDE_SIZE = 3   # columns per side
func side_columns(ally: bool) -> Array:   # ordered FRONT to BACK
	if ally:
		return range(SIDE_SIZE - 1, -1, -1)   # [2, 1, 0]
	return range(SIDE_SIZE, SIDE_SIZE * 2)    # [3, 4, 5]

func get_frontmost_free_slot(row, ally: bool):
	for col in side_columns(ally):
		var s = get_slot(row, col)
		if not s.full:
			return s
	return null

func compact_lane(row, ally: bool):
	var cols = side_columns(ally)
	var write = 0                              # next front-most position to fill
	for read in range(cols.size()):
		var from_slot = get_slot(row, cols[read])
		if not from_slot.character:
			continue
		var to_slot = get_slot(row, cols[write])
		if to_slot != from_slot:
			move_unit(from_slot, to_slot)
		write += 1

func move_unit(from_slot, to_slot):
	var unit = from_slot.character
	from_slot.character = null
	from_slot.full = false
	to_slot.character = unit
	to_slot.full = true
	unit.slot = to_slot
	create_tween().tween_property(unit, "global_position", to_slot.global_position, 0.2)
