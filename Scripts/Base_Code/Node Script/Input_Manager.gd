extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_SLOT = 2

@onready var card_manager = $"../CardManager"
@onready var main_reference = $".."
@onready var skill_menu = $"../SkillTable"
const DRAG_THRESHOLD := 12.0
var _pressed_unit = null
var _press_pos := Vector2.ZERO
var _moving := false

func _input(event):
	if event is InputEventMouseMotion:
		_check_start_move()
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	match main_reference.current_phase:
		main_reference.GamePhase.PLAYER_PREPARATION:
			if event.pressed:
				card_manager.start_drag(raycast_check_for_card(), raycast_check_for_card_slot())
			else:
				card_manager.finish_drag(raycast_check_for_card_slot())
		main_reference.GamePhase.PLAYER_TURN:
			if event.pressed:
				_press_in_turn()
			else:
				_release_in_turn()

func _press_in_turn():
	if skill_menu.visible and skill_menu.get_global_rect().has_point(get_global_mouse_position()):
		return                                      # the click belongs to the menu's buttons
	var unit = raycast_check_for_card()
	if unit and unit.slot:
		_pressed_unit = unit
		_press_pos = get_global_mouse_position()
	else:
		_pressed_unit = null
		skill_menu.hide()
		
func _check_start_move():
	if main_reference.current_phase != main_reference.GamePhase.PLAYER_TURN:
		return
	if _moving or not is_instance_valid(_pressed_unit):
		return
	if get_global_mouse_position().distance_to(_press_pos) < DRAG_THRESHOLD:
		return
	if _pressed_unit.can_move():
		_moving = true
		skill_menu.hide()
		card_manager.start_move(_pressed_unit)
		
func _release_in_turn():
	if _moving:
		card_manager.finish_move(raycast_check_for_card_slot())
	elif is_instance_valid(_pressed_unit) and raycast_check_for_card() == _pressed_unit:
		skill_menu.open(_pressed_unit)              # a click, not a drag
	_moving = false
	_pressed_unit = null

# ---------------- RAYCAST ----------------
func raycast_check_for_card():
	var result = _point_query(COLLISION_MASK_CARD)
	if result.size() > 0:
		return card_on_top(result)
	return null

func raycast_check_for_card_slot():
	var result = _point_query(COLLISION_MASK_SLOT)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func _point_query(mask):
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = mask
	return get_viewport().world_2d.direct_space_state.intersect_point(parameters)

func card_on_top(cards):
	var top_card = cards[0].collider.get_parent()
	var highest_z_index = top_card.z_index
	for card_data in cards:
		var card = card_data.collider.get_parent()
		if card.z_index > highest_z_index:
			top_card = card
			highest_z_index = card.z_index
	return top_card
