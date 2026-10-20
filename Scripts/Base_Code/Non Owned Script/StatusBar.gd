class_name StatusBar
extends HFlowContainer
## Shows one small chip per active status ("Spike 3") under the health bar.
## Add it as a child of a Unit scene (Characters.tscn and Enemies.tscn).

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = FlowContainer.ALIGNMENT_CENTER
	custom_minimum_size.x = Layout.CARD_SIZE.x
	position = Vector2(-Layout.CARD_SIZE.x / 2, Layout.CARD_SIZE.y / 2 + 36)   # under the health bar
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)
	var unit = get_parent()
	unit.statuses_changed.connect(refresh)
	refresh()

func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var unit = get_parent()
	for status in unit.statuses:
		add_child(_make_chip(status, unit.statuses[status]))

func _make_chip(status: String, stacks: int) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = StatusVisuals.color_of(status)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = StatusVisuals.label_of(status) + " " + str(stacks)
	label.add_theme_font_size_override("font_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	return chip
