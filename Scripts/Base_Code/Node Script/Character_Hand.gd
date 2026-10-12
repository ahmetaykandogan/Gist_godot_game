extends Node2D

var max_hand_size = 2

const card_scene_path = "res://Scenes/Characters.tscn"
const hand_y_position = 850
const card_width = 200
var center_screen_x

var player_cards = []
# Called when the node enters the scene tree for the first time.
#Add all the cards when the game starts
@export var roster: Array[CharacterData] = []

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	var card_scene = preload(card_scene_path)
	for character_data in roster:
		var new_card = card_scene.instantiate()
		new_card.data = character_data       # set BEFORE add_child
		$"../CardManager".add_child(new_card)
		new_card.name = "Card"
		add_card_to_hand(new_card)

func add_card_to_hand(new_card): #adds a card to the player hand
	player_cards.insert(0, new_card)
	update_hand_positions()
	
	
func update_hand_positions(): #take all the cards and update their position
	for i in range(player_cards.size()):
		var new_position = Vector2(calculate_new_position(i), hand_y_position)
		player_cards[i].hand_pos = new_position
		animate_card_to_place(player_cards[i], new_position)
		


func calculate_new_position(index): #For each card will find how they should be placed
	var total_width = (player_cards.size() - 1) * card_width
	var x_offset = center_screen_x + index * card_width - total_width / 2
	return x_offset
	
func animate_card_to_place(card, given_position):
	var tween = get_tree().	create_tween()
	tween.tween_property(card, "position", given_position, 0.1)
	

func remove_card_from_hand(card):
	if card in player_cards:
		player_cards.erase(card)
		update_hand_positions()

func all_characters_placed():
	return player_cards.is_empty()

func draw_a_card():
	print("Draw a card")
