extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_SLOT = 2

var screen_size
var card_being_dragged
var is_hovering_on_card = false
var drag_offset = Vector2.ZERO
var player_hand_reference
var main_reference
var taken_from_slot #to check if the card has been taken from a slot to put it back on the hand correctly

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../CharacterHand"
	main_reference = $".."

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		var target_position = mouse_pos + drag_offset
		card_being_dragged.global_position = Vector2(
			clamp(target_position.x, 0, screen_size.x),
			clamp(target_position.y, 0, screen_size.y)
		)

func _input(event):
	if main_reference.current_phase == main_reference.GamePhase.PLAYER_PREPARATION:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var card = raycast_check_for_card()
			var slot = raycast_check_for_card_slot()
			if event.pressed:
				if card:
					#We have to check if we took the card from a slot
					if slot:
						slot.full = false
						taken_from_slot = true
					card_being_dragged = card

					# Remember where on the card the mouse was clicked
					drag_offset = card.global_position - get_global_mouse_position()

					# Put the dragged card above the other cards
					card_being_dragged.z_index = 10
			else:
				if card_being_dragged: #Check if anything happens when the card is released
					if slot and slot.full == false and slot.column <= 2:
						card_being_dragged.position = slot.position
						slot.full = true
						player_hand_reference.remove_card_from_hand(card_being_dragged)
					else:
						if taken_from_slot:
							taken_from_slot = false
							player_hand_reference.add_card_to_hand(card_being_dragged)
						else:
							card_being_dragged.position = card_being_dragged.hand_pos
					card_being_dragged.z_index = 1

				card_being_dragged = null
	if main_reference.current_phase == main_reference.GamePhase.PLAYER_TURN:
		pass


# ----------------------------- RAYCAST -------------------------------------------

func raycast_check_for_card():
	var space_state = get_viewport().world_2d.direct_space_state

	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD

	var result = space_state.intersect_point(parameters)

	if result.size() > 0:
		return card_on_top(result)

	return null
	
func raycast_check_for_card_slot():
	var space_state = get_viewport().world_2d.direct_space_state

	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_SLOT

	var result = space_state.intersect_point(parameters)

	if result.size() > 0:
		return result[0].collider.get_parent()

	return null

func card_on_top(cards):
	var top_card = cards[0].collider.get_parent()
	var highest_z_index = top_card.z_index

	for card_data in cards:
		var card = card_data.collider.get_parent()

		if card.z_index > highest_z_index:
			top_card = card
			highest_z_index = card.z_index

	return top_card


# ----------------------------- HOVER -------------------------------------------

func on_hovered_over_card(card):
	# Don't change hover state while dragging
	if card_being_dragged:
		return

	if not is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)


func on_hovered_off_card(card):
	# Don't change hover state while dragging
	if card_being_dragged:
		return

	highlight_card(card, false)

	var new_card_hovered = raycast_check_for_card()

	if new_card_hovered:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_on_card = false


func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_ended", on_hovered_off_card)


func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1
