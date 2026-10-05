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

var spell_hand_reference

func _ready() -> void:
	screen_size = get_viewport_rect().size
	spell_hand_reference = $"../SpellHand"
	main_reference = $".."
	input_manager = $"../InputManager"

func start_drag(card):
	if not card or main_reference.spell_used:
		return
	card_being_dragged = card
	drag_offset = card.global_position - get_global_mouse_position()
	card_being_dragged.z_index = 10

func finish_drag(slot):
	if not card_being_dragged:
		return
	if slot and slot.character:                      # a character is in that slot
		card_being_dragged.cast(slot.character)
		main_reference.spell_used = true
		spell_hand_reference.remove_card_from_hand(card_being_dragged)
		card_being_dragged.queue_free()
	else:
		card_being_dragged.position = card_being_dragged.hand_pos   # back to hand
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
		card.scale = Vector2(1.1, 1.1)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1
