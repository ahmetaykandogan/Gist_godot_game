extends PanelContainer

var _character = null                       # the unit whose skills are listed

func open(character) -> void:
	_clear_preview()                        # drop any preview left by the previous unit
	if character.has_acted or character.pending_skill:
		hide()
		return
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	_character = character
	for child in $VBoxContainer.get_children():
		$VBoxContainer.remove_child(child)       # detach at once, so old buttons can not be hovered or take space
		child.queue_free()
	for skill in character.skills:
		var button = Button.new()
		button.text = skill.skill_name
		button.mouse_entered.connect(func(): character.set_preview_skill(skill))   # hover: preview, not locked
		button.mouse_exited.connect(func(): character.clear_preview_skill())
		button.pressed.connect(func():                                              # click: lock it in
			character.clear_preview_skill()
			character.try_use_skill(skill)
			hide())
		$VBoxContainer.add_child(button)
	global_position = character.global_position + Vector2(120, 0)
	show()

func _on_visibility_changed() -> void:
	if not visible:
		_clear_preview()

func _clear_preview() -> void:
	if is_instance_valid(_character):
		_character.clear_preview_skill()
	_character = null
