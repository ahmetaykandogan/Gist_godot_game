extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_SLOT = 2
const COLLISION_MASK_DECK = 4
const COLLISION_MASK_SPELL = 8


@onready var card_manager = $"../CardManager"
@onready var main_reference = $".."
@onready var spell_hand_reference = $"../SpellHand"
@onready var spell_manager_reference = $"../SpellManager"
@onready var skill_menu = $"../SkillTable"


func _input(event):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	match main_reference.current_phase:
		main_reference.GamePhase.PLAYER_PREPARATION: #Everything before the game start
			#Since in prestart we only have cards, we know everything is a card already
			if event.pressed:
				card_manager.start_drag(raycast_check_for_card(), raycast_check_for_card_slot())
			else:
				card_manager.finish_drag(raycast_check_for_card_slot())
		main_reference.GamePhase.PLAYER_TURN:
			if event.pressed:
				# A click on the menu itself belongs to its buttons
				if skill_menu.visible and skill_menu.get_global_rect().has_point(get_global_mouse_position()):
					return
				if raycast_check_for_deck():
					#spell_hand_reference.draw_a_card()
					skill_menu.hide()
					return
				var spell = raycast_check_for_spell()
				if spell:
					spell_manager_reference.start_drag(spell)
					skill_menu.hide()
					return
				var character = raycast_check_for_card()
				if character and character.slot:    # only characters already placed
					skill_menu.open(character)
				else:
					skill_menu.hide()
			else:
				spell_manager_reference.finish_drag(raycast_check_for_card_slot())
				

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
	
func raycast_check_for_deck():
	var result = _point_query(COLLISION_MASK_DECK)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null
func raycast_check_for_spell():
	var result = _point_query(COLLISION_MASK_SPELL)
	if result.size() > 0:
		return card_on_top(result)
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
