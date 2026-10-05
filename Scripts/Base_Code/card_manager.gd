extends Node2D

var screen_size
var card_being_dragged
var is_hovering_on_card = false
var drag_offset = Vector2.ZERO
var player_hand_reference
var main_reference
var taken_from_slot #to check if the card has been taken from a slot to put it back on the hand correctly

var input_manager

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		var target_position = mouse_pos + drag_offset
		card_being_dragged.global_position = Vector2(
			clamp(target_position.x, 0, screen_size.x),
			clamp(target_position.y, 0, screen_size.y)
		)

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../CharacterHand"
	main_reference = $".."
	input_manager = $"../InputManager"   # new

func start_drag(card, slot):
	if not card:
		return
	taken_from_slot = slot != null
	if slot:
		slot.full = false
		slot.character = null
		card.slot = null  
	card_being_dragged = card
	drag_offset = card.global_position - get_global_mouse_position()
	card_being_dragged.z_index = 10

func finish_drag(slot):
	if not card_being_dragged:
		return
	if slot and slot.full == false and slot.column <= 2:
		card_being_dragged.position = slot.position
		slot.full = true
		slot.character = card_being_dragged
		card_being_dragged.slot = slot
		player_hand_reference.remove_card_from_hand(card_being_dragged)
	elif taken_from_slot:
		player_hand_reference.add_card_to_hand(card_being_dragged)
	else:
		card_being_dragged.position = card_being_dragged.hand_pos
	taken_from_slot = false
	card_being_dragged.z_index = 1
	card_being_dragged = null

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

	var new_card_hovered = input_manager.raycast_check_for_card()

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
