extends Node2D

var full = false
var row
var column
var character
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sprite = $Sprite2D
	sprite.scale = Layout.SLOT_SIZE / sprite.texture.get_size()
	var shape = RectangleShape2D.new()
	shape.size = Layout.SLOT_SIZE
	$Area2D/CollisionShape2D.shape = shape
