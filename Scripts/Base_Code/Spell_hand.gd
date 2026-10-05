extends Node2D

const spell_scene_path = "res://Scenes/Spell_Cards.tscn"
const hand_y_position = 850
const card_width = 200
var max_hand_size = 6
var center_screen_x
var spell_cards = []
@export var spell_pool: Array[SpellData] = []
var deck: Array[SpellData] = []

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	deck = spell_pool.duplicate()
	deck.shuffle()


func draw_a_card():
	if spell_cards.size() >= max_hand_size:
		print("Hand full")
		return
	if deck.is_empty():
		print("Deck empty")
		return
	var new_card = preload(spell_scene_path).instantiate()
	new_card.data = deck.pop_back()   # removes the card from the deck
	$"../SpellManager".add_child(new_card)
	new_card.position = $"../Deck".position
	add_card_to_hand(new_card)

func add_card_to_hand(card):
	spell_cards.insert(0, card)
	update_hand_positions()

func remove_card_from_hand(card):
	if card in spell_cards:
		spell_cards.erase(card)
		update_hand_positions()

func update_hand_positions():
	for i in range(spell_cards.size()):
		var new_position = Vector2(calculate_new_position(i), hand_y_position)
		spell_cards[i].hand_pos = new_position
		animate_card_to_place(spell_cards[i], new_position)

func calculate_new_position(index):
	var total_width = (spell_cards.size() - 1) * card_width
	return center_screen_x + index * card_width - total_width / 2

func animate_card_to_place(card, given_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", given_position, 0.1)
