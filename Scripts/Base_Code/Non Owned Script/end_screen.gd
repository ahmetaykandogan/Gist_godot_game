extends CanvasLayer
## Victory / Defeat screen, winter style. Builds its own interface (same approach as
## start_screen.gd and options_menu.gd), so Victory.tscn and Defeat.tscn stay tiny.
## Both scenes use this one script; only the "result" setting is different.
## Restart -> the battle starts again.  Main Menu -> back to the title screen.

enum Result { VICTORY, DEFEAT }

const GAME_SCENE := "res://Scenes/main.tscn"
const MENU_SCENE := "res://Scenes/StartScreen.tscn"

# ------------------------------- LOOK (edit freely) ---------------------------
const WOOD := Color("7a3b2a")
const WOOD_DARK := Color("3a1c17")
const WOOD_INNER := Color("4d2420")
const CREAM := Color("f9e2b0")
const RED := Color("d24b3e")
const RED_LIGHT := Color("e8685a")
const RED_DARK := Color("5b1d1f")
const SNOW_PANEL := Color("f1faff")
const SNOW_EDGE := Color("b9d9ee")

const VICTORY_DIM := Color(0.10, 0.35, 0.62, 0.55)    # bright winter blue over the battle
const DEFEAT_DIM := Color(0.06, 0.05, 0.12, 0.78)     # dark and heavy
const VICTORY_TITLE := CREAM
const DEFEAT_TITLE := Color("f0b4aa")
const CONFETTI_COLORS: Array[Color] = [
	RED_LIGHT, CREAM, Color("7fd0ff"), Color.WHITE, Color("ffd24a"), Color("8be28b")]

@export var result: Result = Result.VICTORY
@export var title_text := ""                  # leave empty to use the default of the result
@export var message_text := ""                # leave empty to use the default of the result
@export var badge_text := "GIST"
@export var title_font: Font                  # optional: same font as the title screen

var _root: Control
var _fade: ColorRect
var _leaving := false


func _ready() -> void:
	layer = 20                                # above the game and the Options menu (layer 10)
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_dim()
	_build_snow()
	if result == Result.VICTORY:
		_build_confetti()
	var sign_root := _build_sign()
	var restart_button := _build_restart_button()
	var menu_button := _build_menu_button()
	_build_fade()
	_animate_in(sign_root, restart_button, menu_button)
	restart_button.grab_focus()               # so Enter restarts right away


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Escape: keep the Options menu closed on this screen
		get_viewport().set_input_as_handled()


# ============================ RESTART / MAIN MENU =============================
func _on_restart_pressed() -> void:
	_leave_to(GAME_SCENE)


func _on_menu_pressed() -> void:
	_leave_to(MENU_SCENE)


func _leave_to(scene_path: String) -> void:
	if _leaving:
		return
	_leaving = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)


# ================================== BACKGROUND ================================
func _build_dim() -> void:
	var vp := get_viewport().get_visible_rect().size
	var dim := ColorRect.new()                    # blocks clicks on the game behind it
	dim.color = VICTORY_DIM if result == Result.VICTORY else DEFEAT_DIM
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_in(dim, 0.0)

	if result == Result.VICTORY:                  # soft light behind the sign
		var glow := TextureRect.new()
		glow.texture = _radial(Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0), 0.0)
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(glow)
		glow.size = Vector2(1500, 1100) * (vp.y / 1080.0)
		glow.position = vp * Vector2(0.5, 0.42) - glow.size * 0.5
		_fade_in(glow, 0.1)


func _build_snow() -> void:
	var vp := get_viewport().get_visible_rect().size
	var victory := result == Result.VICTORY
	var p := CPUParticles2D.new()
	p.texture = _radial(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.0, 32)
	p.amount = 110 if victory else 60
	p.lifetime = 14.0
	p.preprocess = 14.0                           # the screen is already full of flakes on frame 1
	p.position = Vector2(vp.x * 0.5, -20.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.6, 10.0)
	p.direction = Vector2(0.15, 1.0)
	p.spread = 12.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0 if victory else 25.0
	p.initial_velocity_max = 100.0 if victory else 60.0
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.38
	_root.add_child(p)


# ================================== CONFETTI ==================================
# One burst from each side of the screen when the Victory scene opens. It plays once.
func _build_confetti() -> void:
	var vp := get_viewport().get_visible_rect().size
	var k := vp.y / 1080.0

	var palette := Gradient.new()                 # each piece gets one random colour of the list
	palette.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / CONFETTI_COLORS.size())
		colors.append(CONFETTI_COLORS[i])
	palette.offsets = offsets
	palette.colors = colors

	var fade := Gradient.new()                    # pieces fade out at the end of their life
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])

	for side in [-1.0, 1.0]:                      # -1 = left edge, 1 = right edge
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.amount = 80
		p.lifetime = 3.2
		p.explosiveness = 0.9
		p.position = Vector2(0.0 if side < 0.0 else vp.x, vp.y * 0.75)
		p.direction = Vector2(-side * 0.6, -1.0).normalized()   # up and towards the middle
		p.spread = 28.0
		p.gravity = Vector2(0, 1100.0 * k)
		p.initial_velocity_min = 900.0 * k
		p.initial_velocity_max = 1500.0 * k
		p.damping_min = 120.0
		p.damping_max = 220.0
		p.angle_min = -180.0
		p.angle_max = 180.0
		p.angular_velocity_min = -540.0              # the pieces tumble while they fall
		p.angular_velocity_max = 540.0
		p.scale_amount_min = 7.0 * k                 # no texture: each piece is a small square
		p.scale_amount_max = 14.0 * k
		p.color_initial_ramp = palette
		p.color_ramp = fade
		p.finished.connect(p.queue_free)
		_root.add_child(p)
		p.emitting = true


# ===================================== SIGN ===================================
# The same wooden sign with a snowy top and a diamond badge as the title screen.
func _build_sign() -> Control:
	var victory := result == Result.VICTORY
	var sign_root := Control.new()
	sign_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(sign_root)
	_place(sign_root, Rect2(-400, -400, 800, 370))

	var wood := Panel.new()
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wood.add_theme_stylebox_override("panel", _box(WOOD, WOOD_DARK, 7, 30, true))
	sign_root.add_child(wood)
	wood.position = Vector2(10, 70)
	wood.size = Vector2(780, 300)

	var inner := Panel.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", _box(WOOD_INNER, Color("8d4a33"), 4, 20, false))
	sign_root.add_child(inner)
	inner.position = Vector2(40, 100)
	inner.size = Vector2(720, 240)

	var snow := Panel.new()
	snow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snow.add_theme_stylebox_override("panel", _box(SNOW_PANEL, SNOW_EDGE, 3, 34, false))
	sign_root.add_child(snow)
	snow.position = Vector2(0, 50)
	snow.size = Vector2(800, 66)

	var bump := Panel.new()
	bump.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bump.add_theme_stylebox_override("panel", _box(SNOW_PANEL, SNOW_EDGE, 3, 30, false))
	sign_root.add_child(bump)
	bump.position = Vector2(560, 28)
	bump.size = Vector2(190, 56)

	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _box(WOOD, WOOD_DARK, 6, 10, true))
	sign_root.add_child(badge)
	badge.size = Vector2(104, 104)
	badge.position = Vector2(400 - 52, 34 - 52 + 26)
	badge.pivot_offset = badge.size * 0.5
	badge.rotation_degrees = 45.0

	var badge_label := Label.new()
	badge_label.text = badge_text
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 40)
	badge_label.add_theme_color_override("font_color", CREAM)
	badge_label.add_theme_color_override("font_outline_color", WOOD_DARK)
	badge_label.add_theme_constant_override("outline_size", 8)
	if title_font:
		badge_label.add_theme_font_override("font", title_font)
	sign_root.add_child(badge_label)
	badge_label.size = Vector2(140, 50)
	badge_label.position = Vector2(330, 36)

	var title := Label.new()
	title.text = title_text if title_text != "" else ("VICTORY!" if victory else "DEFEAT")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 128)
	title.add_theme_color_override("font_color", VICTORY_TITLE if victory else DEFEAT_TITLE)
	title.add_theme_color_override("font_outline_color", WOOD_DARK)
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	title.add_theme_constant_override("shadow_offset_y", 6)
	if title_font:
		title.add_theme_font_override("font", title_font)
	sign_root.add_child(title)
	title.size = Vector2(720, 170)
	title.position = Vector2(40, 118)

	var message := Label.new()
	message.text = message_text if message_text != "" else ("All enemies defeated" if victory else "Your party has fallen")
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 34)
	message.add_theme_color_override("font_color", SNOW_PANEL)
	message.add_theme_color_override("font_outline_color", WOOD_DARK)
	message.add_theme_constant_override("outline_size", 8)
	if title_font:
		message.add_theme_font_override("font", title_font)
	sign_root.add_child(message)
	message.size = Vector2(720, 50)
	message.position = Vector2(40, 280)
	return sign_root


# ==================================== BUTTONS =================================
# Restart: the red hexagon button of the title screen. It is focused, so Enter works.
func _build_restart_button() -> Button:
	var size := Vector2(420, 84)
	var button := Button.new()
	button.text = "Restart"
	button.add_theme_font_size_override("font_size", 52)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color.WHITE)
	button.add_theme_color_override("font_outline_color", RED_DARK)
	button.add_theme_constant_override("outline_size", 8)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if title_font:
		button.add_theme_font_override("font", title_font)
	button.pressed.connect(_on_restart_pressed)
	_root.add_child(button)
	_place(button, Rect2(-size.x * 0.5, 20, size.x, size.y))

	# hexagon art drawn behind the button's text
	var border := _poly_to(button, _hex(Vector2(-5, -5), size + Vector2(10, 10)), RED_DARK)
	var body := _poly_to(button, _hex(Vector2.ZERO, size), RED)
	var shine := _poly_to(button, PackedVector2Array([
		Vector2(size.y * 0.5, 0), Vector2(size.x - size.y * 0.5, 0),
		Vector2(size.x, size.y * 0.5), Vector2(0, size.y * 0.5)]), Color(1, 1, 1, 0.14))
	border.show_behind_parent = true
	body.show_behind_parent = true
	shine.show_behind_parent = true
	for x in [size.x * 0.115, size.x * 0.885]:
		var gem := ColorRect.new()
		gem.color = CREAM
		gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gem.show_behind_parent = true
		button.add_child(gem)
		gem.size = Vector2(16, 16)
		gem.position = Vector2(x - 8.0, size.y * 0.5 - 8.0)
		gem.pivot_offset = gem.size * 0.5
		gem.rotation_degrees = 45.0
	button.mouse_entered.connect(func(): body.color = RED_LIGHT)
	button.mouse_exited.connect(func(): body.color = RED_LIGHT if button.has_focus() else RED)
	button.focus_entered.connect(func(): body.color = RED_LIGHT)
	button.focus_exited.connect(func(): body.color = RED)
	body.color = RED_LIGHT                        # focused from the start
	_wire_hover(button, 1.06)
	return button


# Main Menu: the smaller frosted-blue button of the title screen (the Quit style).
func _build_menu_button() -> Button:
	var button := Button.new()
	button.text = "Main Menu"
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("dff3ff"))
	button.add_theme_color_override("font_outline_color", Color("1f5f9a"))
	button.add_theme_constant_override("outline_size", 6)
	button.add_theme_stylebox_override("normal", _box(Color(0.1, 0.3, 0.6, 0.35), Color(1, 1, 1, 0.6), 2, 24, false))
	button.add_theme_stylebox_override("hover", _box(Color(0.1, 0.3, 0.6, 0.6), Color.WHITE, 2, 24, false))
	button.add_theme_stylebox_override("pressed", _box(Color(0.1, 0.3, 0.6, 0.8), Color.WHITE, 2, 24, false))
	if title_font:
		button.add_theme_font_override("font", title_font)
	button.pressed.connect(_on_menu_pressed)
	_root.add_child(button)
	_place(button, Rect2(-150, 132, 300, 62))
	_wire_hover(button, 1.05)
	return button


func _hex(pos: Vector2, s: Vector2) -> PackedVector2Array:
	var inset := s.y * 0.5
	return PackedVector2Array([
		pos + Vector2(inset, 0), pos + Vector2(s.x - inset, 0), pos + Vector2(s.x, s.y * 0.5),
		pos + Vector2(s.x - inset, s.y), pos + Vector2(inset, s.y), pos + Vector2(0, s.y * 0.5)])


func _wire_hover(b: Button, grown: float) -> void:
	b.mouse_entered.connect(func(): _scale_to(b, grown))
	b.mouse_exited.connect(func(): _scale_to(b, 1.0))


func _scale_to(c: Control, s: float) -> void:
	var old: Tween = c.get_meta("scale_tween") if c.has_meta("scale_tween") else null
	if old:
		old.kill()
	var t := create_tween()
	c.set_meta("scale_tween", t)
	t.tween_property(c, "scale", Vector2(s, s), 0.12).set_trans(Tween.TRANS_SINE)


# ================================ FADES / INTRO ===============================
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE   # becomes STOP while leaving
	_root.add_child(_fade)                             # added last = drawn on top of everything
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _animate_in(sign_root: Control, restart_button: Control, menu_button: Control) -> void:
	_fade_in(sign_root, 0.15)
	sign_root.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(sign_root, "scale", Vector2.ONE, 0.5) \
		.set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fade_in(restart_button, 0.6)
	_fade_in(menu_button, 0.75)


func _fade_in(node: CanvasItem, delay: float) -> void:
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.5).set_delay(delay)


# ===================================== HELPERS ================================
# Position a control relative to the CENTRE of the screen (so it stays centred if the window is resized).
func _place(c: Control, rect: Rect2) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = rect.position.x
	c.offset_top = rect.position.y
	c.offset_right = rect.end.x
	c.offset_bottom = rect.end.y
	c.pivot_offset = rect.size * 0.5


func _poly_to(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	parent.add_child(p)
	return p


func _box(bg: Color, border: Color, border_width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 6)
	return s


func _radial(inner: Color, outer: Color, inner_stop: float, px: int = 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	g.set_offset(0, inner_stop)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = px
	tex.height = px
	return tex
