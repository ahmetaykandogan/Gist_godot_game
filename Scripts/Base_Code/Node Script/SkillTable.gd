extends PanelContainer

func open(character):
	if character.has_acted:
		hide()
		return
	for child in $VBoxContainer.get_children():
		child.queue_free()
	for skill in character.skills:
		var button = Button.new()
		button.text = skill.skill_name
		button.pressed.connect(func():
			character.try_use_skill(skill)
			hide())
		$VBoxContainer.add_child(button)
	global_position = character.global_position + Vector2(120, 0)
	show()
