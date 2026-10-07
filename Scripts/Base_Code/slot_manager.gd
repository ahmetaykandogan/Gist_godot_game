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
	var x_position = 210 + column * 300
	var y_position = 250 + row * 300
	
	slot.position = Vector2(x_position, y_position)

func get_slot(row, column):
	if row < 0 or row >= Row_depth or column < 0 or column >= Row_length:
		return null   # outside the board
	return character_slots[row][column]

# The slot directly next to this one, toward the enemy side
func get_slot_in_front(slot):
	var direction = 1 if slot.column <= 2 else -1  
	return get_slot(slot.row, slot.column + direction)
	
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
