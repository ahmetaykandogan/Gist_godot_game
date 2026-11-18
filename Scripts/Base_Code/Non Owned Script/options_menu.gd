class_name OptionsMenu
extends CanvasLayer
## "Options" button (top right) and its menu: volume, restart, quit. It builds its own interface.

signal restart_confirmed
signal quit_confirmed

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_VOLUME := 0.8
const CONFIRM_SECONDS := 2.5            # time to click a second time on Restart / Quit
const BUTTON_SHIFT_LEFT := 100          # moves the Options button this many pixels left of the corner

var _root: Control                      # dim background + panel, hidden while the menu is closed
var _slider: HSlider
var _percent: Label
var _restart_button: Button
var _quit_button: Button
var _armed: Button = null               # the button waiting for its second click

func _ready() -> void:
	layer = 10                          # above the game and its other buttons
	_build_ui()
	_slider.value_changed.connect(_on_volume_changed)
	_slider.value = _load_volume()
	_on_volume_changed(_slider.value)
	_root.visible = false
	restart_confirmed.connect(_restart)
	quit_confirmed.connect(_quit)


# ================================= OPEN / CLOSE ===============================
func is_open() -> bool:
	return _root.visible

func open() -> void:
	_root.visible = true

func close() -> void:
	_disarm()
	_save_volume()
	_root.visible = false

func toggle() -> void:
	if is_open():
		close()
	else:
		open()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):          # the Escape key
		toggle()
		get_viewport().set_input_as_handled()


# ==================================== VOLUME ==================================
# The slider drives the Master bus, so it controls every sound and the music.
func _on_volume_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, value <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.001)))
	_percent.text = "%d%%" % roundi(value * 100.0)

func _load_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		return clampf(float(cfg.get_value("audio", "volume", DEFAULT_VOLUME)), 0.0, 1.0)
	return DEFAULT_VOLUME

func _save_volume() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)                           # keep any other saved settings
	cfg.set_value("audio", "volume", _slider.value)
	cfg.save(SETTINGS_PATH)


# ============================= RESTART / QUIT =================================
func _on_restart_pressed() -> void:
	_confirm(_restart_button, restart_confirmed)

func _on_quit_pressed() -> void:
	_confirm(_quit_button, quit_confirmed)

# The first click arms the button ("Sure? Click again"), the second one does the action.
func _confirm(button: Button, done: Signal) -> void:
	if _armed == button:
		_disarm()
		done.emit()
		return
	_disarm()
	_armed = button
	button.text = "Sure? Click again"
	get_tree().create_timer(CONFIRM_SECONDS).timeout.connect(func():
		if _armed == button:
			_disarm())

func _disarm() -> void:
	_armed = null
	_restart_button.text = "Restart"
	_quit_button.text = "Quit"

func _restart() -> void:
	_save_volume()
	get_tree().reload_current_scene.call_deferred()   # the whole battle starts again

func _quit() -> void:
	_save_volume()
	get_tree().quit()


# ================================== INTERFACE =================================
func _build_ui() -> void:
	var open_button := Button.new()
	open_button.text = "Options"
	open_button.custom_minimum_size = Vector2(140, 48)
	open_button.focus_mode = Control.FOCUS_NONE
	add_child(open_button)
	open_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	open_button.offset_left -= BUTTON_SHIFT_LEFT
	open_button.offset_right -= BUTTON_SHIFT_LEFT
	open_button.pressed.connect(open)

	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()                       # blocks clicks on the game while the menu is open
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Options"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var volume_label := Label.new()
	volume_label.text = "Volume"
	volume_label.custom_minimum_size.x = 110
	row.add_child(volume_label)
	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.custom_minimum_size = Vector2(240, 32)
	row.add_child(_slider)
	_percent = Label.new()
	_percent.custom_minimum_size.x = 70
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_percent)

	var resume_button := _make_button("Resume", box)
	resume_button.pressed.connect(close)
	_restart_button = _make_button("Restart", box)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button = _make_button("Quit", box)
	_quit_button.pressed.connect(_on_quit_pressed)

func _make_button(text: String, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	parent.add_child(b)
	return b
