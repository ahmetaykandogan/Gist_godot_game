extends Button


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
