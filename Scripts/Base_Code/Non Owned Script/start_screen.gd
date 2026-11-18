extends Control
## Title screen, winter style. Builds its own interface (same approach as options_menu.gd),
## so the .tscn stays tiny. Start -> screen fades to black -> the game scene loads.

const GAME_SCENE := "res://Scenes/main.tscn"

# ------------------------------- LOOK (edit freely) ---------------------------
const SKY_TOP := Color("2c9be6")
const SKY_BOTTOM := Color("aedff9")
const MOUNTAIN_FAR := Color("86bdea")
const MOUNTAIN_MID := Color("5f9bd8")
const SNOW := Color("f4fbff")
const SNOW_SHADE := Color("c4def0")
const PINE := Color("2d7388")
const WOOD := Color("7a3b2a")
const WOOD_DARK := Color("3a1c17")
const WOOD_INNER := Color("4d2420")
const CREAM := Color("f9e2b0")
const RED := Color("d24b3e")
const RED_LIGHT := Color("e8685a")
const RED_DARK := Color("5b1d1f")
const BANNER_RED := Color("c23b3d")
const CARD_BODY := Color("46579c")
const CARD_EDGE := Color("e9d29a")
const CARD_SIZE := Vector2(170, 240)

# Cards sit bottom-left, like the stall in the reference image (coords from screen centre).
const FAN_X: Array[float] = [-690.0, -560.0, -430.0]
const FAN_ANGLE: Array[float] = [-12.0, 6.0, 18.0]
const FAN_Y: Array[float] = [400.0, 420.0, 395.0]

# The art shown on the cards. Replace with your own in the Inspector (card_art) if you like.
const DEFAULT_ART: Array[String] = [
	"res://Arts/Actual art/Golems (1).jpg",
	"res://Arts/Actual art/Seamstress.jpg",
	"res://Arts/Actual art/Mage.jpg",
]

@export var game_title := "Card Game"
@export var badge_text := "GIST"
@export var subtitle := ""                   # leave empty to hide (the reference has none)
@export var title_font: Font                 # optional: drop a .ttf in the project and assign it here
@export var card_art: Array[Texture2D] = []  # leave empty to use DEFAULT_ART

var _time := 0.0
var _starting := false
var _cards: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []
var _banners: Array[Dictionary] = []
var _crystal: Node2D
var _crystal_base := Vector2.ZERO
var _start_button: Button
var _start_body: Polygon2D
var _quit_button: Button
var _fade: ColorRect
var _fade_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_scenery()
	_build_snow()
	_build_cards()
	_build_title()
	_build_buttons()
	_build_fade()
	_start_button.grab_focus()               # so Enter starts the game right away


func _process(delta: float) -> void:
	_time += delta
	_update_cards()
	_update_scenery(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Enter / Space even if the button lost focus
		_on_start_pressed()


# ================================= START / QUIT ===============================
func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "color:a", 1.0, 0.45)
	await _fade_tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	if not _starting:
		get_tree().quit()


# ================================== SCENERY ===================================
func _build_scenery() -> void:
	var vp := get_viewport_rect().size
	var k := vp.y / 1080.0

	# sky
	var grad := Gradient.new()
	grad.set_color(0, SKY_TOP)
	grad.set_color(1, SKY_BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# soft light behind the title
	var glow := TextureRect.new()
	glow.texture = _radial(Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0), 0.0)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	glow.size = Vector2(1500, 1100) * k
	glow.position = vp * Vector2(0.5, 0.42) - glow.size * 0.5

	# drifting clouds
	var cloud_data: Array = [[0.06, 0.08, 1.0, 7.0], [0.72, 0.05, 1.2, 5.0], [0.86, 0.22, 0.8, 9.0]]
	for c in cloud_data:
		_add_cloud(Vector2(float(c[0]) * vp.x, float(c[1]) * vp.y), float(c[2]) * k, float(c[3]))

	# mountains: [centre x, base y, width, height] as fractions of the screen
	var far: Array = [[0.12, 0.68, 0.28, 0.24], [0.38, 0.68, 0.34, 0.30], [0.60, 0.68, 0.40, 0.38], [0.84, 0.68, 0.30, 0.26]]
	for m in far:
		_mountain(vp, m, MOUNTAIN_FAR, Color("f2faff"))
	var mid: Array = [[0.22, 0.76, 0.40, 0.20], [0.52, 0.76, 0.46, 0.26], [0.86, 0.76, 0.40, 0.22]]
	for m in mid:
		_mountain(vp, m, MOUNTAIN_MID, Color("eaf6ff"))

	# back hill, trees, front hills
	_hill(vp, 0.80, 0.014, 0.004, 0.5, SNOW_SHADE)
	_hill(vp, 0.795, 0.014, 0.004, 0.5, Color("e3f2fc"))
	var trees: Array = [[0.25, 0.81, 170.0], [0.31, 0.79, 120.0], [0.76, 0.80, 160.0], [0.83, 0.78, 215.0], [0.91, 0.82, 130.0]]
	for t in trees:
		_pine(Vector2(float(t[0]) * vp.x, float(t[1]) * vp.y), float(t[2]) * k)
	_hill(vp, 0.885, 0.02, 0.003, 2.0, SNOW_SHADE)
	_hill(vp, 0.875, 0.02, 0.003, 2.0, SNOW)

	# banners (left tall, right shorter and lower)
	_banner(Vector2(0.15 * vp.x, 0.05 * vp.y), 170.0 * k, 330.0 * k, 0.0)
	_banner(Vector2(0.90 * vp.x, 0.33 * vp.y), 140.0 * k, 240.0 * k, 1.7)

	# floating crystal
	_crystal = Node2D.new()
	add_child(_crystal)
	_crystal_base = vp * Vector2(0.79, 0.17)
	_crystal.position = _crystal_base
	_crystal.scale = Vector2(k, k)
	var top := Vector2(0, -100)
	var right := Vector2(60, 0)
	var bottom := Vector2(0, 120)
	var left := Vector2(-60, 0)
	_poly_to(_crystal, PackedVector2Array([top, right, bottom, left]), Color(0.62, 0.86, 1.0, 0.85))
	_poly_to(_crystal, PackedVector2Array([top, right, bottom]), Color(0.86, 0.96, 1.0, 0.6))
	_poly_to(_crystal, PackedVector2Array([Vector2(0, -40), Vector2(26, 0), Vector2(0, 70), Vector2(-26, 0)]), Color(1, 1, 1, 0.35))
	var outline := Line2D.new()
	outline.points = PackedVector2Array([top, right, bottom, left])
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color(1, 1, 1, 0.8)
	_crystal.add_child(outline)


func _build_snow() -> void:
	var vp := get_viewport_rect().size
	var p := CPUParticles2D.new()
	p.texture = _radial(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.0, 32)
	p.amount = 130
	p.lifetime = 14.0
	p.preprocess = 14.0                      # the screen is already full of flakes on frame 1
	p.position = Vector2(vp.x * 0.5, -20.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.6, 10.0)
	p.direction = Vector2(0.15, 1.0)
	p.spread = 12.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 100.0
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.38
	add_child(p)


func _update_scenery(delta: float) -> void:
	var vp := get_viewport_rect().size
	for c in _clouds:
		var node: Control = c["node"]
		node.position.x += float(c["speed"]) * delta
		if node.position.x > vp.x + 50.0:
			node.position.x = -400.0
	for b in _banners:
		var bn: Node2D = b["node"]
		bn.rotation = sin(_time * 1.1 + float(b["phase"])) * 0.03
	if _crystal:
		_crystal.position = _crystal_base + Vector2(0, sin(_time * 1.2) * 12.0)
		_crystal.rotation = sin(_time * 0.7) * 0.04


func _add_cloud(pos: Vector2, s: float, speed: float) -> void:
	var cloud := Control.new()
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud.modulate.a = 0.9
	add_child(cloud)
	cloud.position = pos
	cloud.scale = Vector2(s, s)
	var parts: Array = [Rect2(0, 30, 320, 70), Rect2(40, 0, 140, 100), Rect2(160, 12, 120, 80)]
	for r: Rect2 in parts:
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _box(Color(1, 1, 1, 0.85), Color(1, 1, 1, 0), 0, 50, false))
		cloud.add_child(panel)
		panel.position = r.position
		panel.size = r.size
	_clouds.append({"node": cloud, "speed": speed})


func _mountain(vp: Vector2, m: Array, body: Color, cap: Color) -> void:
	var cx: float = float(m[0]) * vp.x
	var base: float = float(m[1]) * vp.y
	var w: float = float(m[2]) * vp.x
	var h: float = float(m[3]) * vp.y
	var peak := Vector2(cx, base - h)
	_poly(PackedVector2Array([Vector2(cx - w * 0.5, base + 4), peak, Vector2(cx + w * 0.5, base + 4)]), body)
	_poly(PackedVector2Array([
		peak,
		Vector2(cx + w * 0.5 * 0.36, base - h * 0.64),
		Vector2(cx + w * 0.07, base - h * 0.72),
		Vector2(cx, base - h * 0.62),
		Vector2(cx - w * 0.08, base - h * 0.72),
		Vector2(cx - w * 0.5 * 0.36, base - h * 0.64),
	]), cap)


func _pine(base: Vector2, s: float) -> void:
	_poly(PackedVector2Array([
		base + Vector2(-s * 0.06, 0), base + Vector2(s * 0.06, 0),
		base + Vector2(s * 0.06, -s * 0.2), base + Vector2(-s * 0.06, -s * 0.2)]), Color("5b3a2e"))
	for i in 3:
		var apex := base + Vector2(0, -s * 1.15 + i * s * 0.3)
		var half := s * (0.26 + 0.12 * i)
		var bottom := apex.y + s * 0.55
		_poly(PackedVector2Array([apex, Vector2(apex.x + half, bottom), Vector2(apex.x - half, bottom)]), PINE)
		_poly(PackedVector2Array([
			apex,
			Vector2(apex.x + half * 0.5, apex.y + s * 0.2),
			Vector2(apex.x + half * 0.15, apex.y + s * 0.16),
			Vector2(apex.x - half * 0.2, apex.y + s * 0.24),
			Vector2(apex.x - half * 0.5, apex.y + s * 0.2)]), SNOW)


func _hill(vp: Vector2, base_ratio: float, amp_ratio: float, freq: float, phase: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= vp.x + 40.0:
		pts.append(Vector2(x, vp.y * base_ratio + sin(x * freq + phase) * vp.y * amp_ratio))
		x += 40.0
	pts.append(Vector2(vp.x + 40.0, vp.y))
	pts.append(Vector2(0, vp.y))
	_poly(pts, color)


func _banner(pos: Vector2, w: float, h: float, phase: float) -> void:
	# pole + crossbar
	_poly(PackedVector2Array([
		pos + Vector2(-w * 0.5 - 22, -40), pos + Vector2(-w * 0.5 - 6, -40),
		pos + Vector2(-w * 0.5 - 6, h * 2.2), pos + Vector2(-w * 0.5 - 22, h * 2.2)]), Color("9a5a2c"))
	_poly(PackedVector2Array([
		pos + Vector2(-w * 0.5 - 22, -14), pos + Vector2(w * 0.5 + 10, -14),
		pos + Vector2(w * 0.5 + 10, 4), pos + Vector2(-w * 0.5 - 22, 4)]), Color("b36a33"))
	# cloth (swings from its top edge)
	var node := Node2D.new()
	add_child(node)
	node.position = pos + Vector2(0, 4)
	var shape := PackedVector2Array([
		Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5, h),
		Vector2(0, h - h * 0.14), Vector2(-w * 0.5, h)])
	_poly_to(node, shape, BANNER_RED)
	var edge := Line2D.new()
	edge.points = shape
	edge.closed = true
	edge.width = 4.0
	edge.default_color = RED_DARK
	node.add_child(edge)
	var trim := Line2D.new()
	trim.points = PackedVector2Array([
		Vector2(-w * 0.5 + 12, 14), Vector2(w * 0.5 - 12, 14), Vector2(w * 0.5 - 12, h - 28),
		Vector2(0, h - h * 0.14 - 18), Vector2(-w * 0.5 + 12, h - 28)])
	trim.closed = true
	trim.width = 2.0
	trim.default_color = Color("f2b27a")
	node.add_child(trim)
	var label := Label.new()
	label.text = badge_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(w * 0.42))
	label.add_theme_color_override("font_color", Color("fbe4d8"))
	label.add_theme_color_override("font_outline_color", RED_DARK)
	label.add_theme_constant_override("outline_size", 6)
	if title_font:
		label.add_theme_font_override("font", title_font)
	node.add_child(label)
	label.size = Vector2(w, h * 0.3)
	label.position = Vector2(-w * 0.5, h * 0.22)
	_banners.append({"node": node, "phase": phase})


# ===================================== CARDS ==================================
func _build_cards() -> void:
	var textures: Array[Texture2D] = []
	for t in card_art:
		textures.append(t)
	if textures.is_empty():
		for path in DEFAULT_ART:
			if ResourceLoader.exists(path):
				textures.append(load(path) as Texture2D)

	var order: Array[int] = [0, 2, 1]  # middle card is added last, so it sits on top
	for idx: int in order:
		var card := Panel.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", _box(CARD_BODY, CARD_EDGE, 4, 12, true))
		add_child(card)
		_place(card, Rect2(Vector2(FAN_X[idx], FAN_Y[idx]) - CARD_SIZE * 0.5, CARD_SIZE))
		card.modulate.a = 0.0

		if not textures.is_empty():
			var pic := TextureRect.new()
			pic.texture = textures[idx % textures.size()]
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic.clip_contents = true
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(pic)
			pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
		else:
			var gem := ColorRect.new()          # no art found: simple diamond like the card backs
			gem.color = CARD_EDGE
			gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(gem)
			gem.size = Vector2(40, 40)
			gem.position = CARD_SIZE * 0.5 - gem.size * 0.5
			gem.pivot_offset = gem.size * 0.5
			gem.rotation_degrees = 45.0

		_cards.append({
			"node": card,
			"center": Vector2(FAN_X[idx], FAN_Y[idx]),
			"angle": FAN_ANGLE[idx],
			"phase": idx * 1.3,
			"depth": 0.5 + absf(idx - 1) * 0.25,
			"delay": 0.25 + absf(idx - 1) * 0.12,
		})


# Cards fly in, then float gently and lean a little away from the mouse.
func _update_cards() -> void:
	var vp := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position() / vp - Vector2(0.5, 0.5)
	for d in _cards:
		var card: Panel = d["node"]
		var t := clampf((_time - float(d["delay"])) / 0.8, 0.0, 1.0)
		var e := _ease_out_back(t)
		var depth: float = d["depth"]
		var phase: float = d["phase"]
		var base: Vector2 = d["center"]
		var c := base + Vector2(
			-mouse.x * 20.0 * depth,
			sin(_time * 1.3 + phase) * 6.0 - mouse.y * 10.0 * depth + (1.0 - e) * 700.0)
		card.offset_left = c.x - CARD_SIZE.x * 0.5
		card.offset_right = c.x + CARD_SIZE.x * 0.5
		card.offset_top = c.y - CARD_SIZE.y * 0.5
		card.offset_bottom = c.y + CARD_SIZE.y * 0.5
		card.rotation_degrees = float(d["angle"]) + sin(_time * 0.9 + phase) * 1.2
		card.modulate.a = t


func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)


# ===================================== TITLE ==================================
# A wooden sign with a snowy top and a diamond badge, like in the reference.
func _build_title() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_place(root, Rect2(-400, -480, 800, 440))

	var wood := Panel.new()
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wood.add_theme_stylebox_override("panel", _box(WOOD, WOOD_DARK, 7, 30, true))
	root.add_child(wood)
	wood.position = Vector2(10, 70)
	wood.size = Vector2(780, 370)

	var inner := Panel.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", _box(WOOD_INNER, Color("8d4a33"), 4, 20, false))
	root.add_child(inner)
	inner.position = Vector2(40, 100)
	inner.size = Vector2(720, 310)

	var snow := Panel.new()
	snow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snow.add_theme_stylebox_override("panel", _box(Color("f1faff"), Color("b9d9ee"), 3, 34, false))
	root.add_child(snow)
	snow.position = Vector2(0, 50)
	snow.size = Vector2(800, 66)
	var bump := Panel.new()
	bump.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bump.add_theme_stylebox_override("panel", _box(Color("f1faff"), Color("b9d9ee"), 3, 30, false))
	root.add_child(bump)
	bump.position = Vector2(560, 28)
	bump.size = Vector2(190, 56)

	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _box(WOOD, WOOD_DARK, 6, 10, true))
	root.add_child(badge)
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
	root.add_child(badge_label)
	badge_label.size = Vector2(140, 50)
	badge_label.position = Vector2(330, 36)

	var title := Label.new()
	title.text = game_title.to_upper().replace(" ", "\n")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 128)
	title.add_theme_constant_override("line_spacing", -26)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_color_override("font_outline_color", WOOD_DARK)
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	title.add_theme_constant_override("shadow_offset_y", 6)
	if title_font:
		title.add_theme_font_override("font", title_font)
	root.add_child(title)
	title.size = Vector2(720, 310)
	title.position = Vector2(40, 112)
	_fade_in(root, 0.1)

	if subtitle != "":
		var sub := Label.new()
		sub.text = subtitle
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 32)
		sub.add_theme_color_override("font_color", Color.WHITE)
		sub.add_theme_color_override("font_outline_color", Color("1f5f9a"))
		sub.add_theme_constant_override("outline_size", 8)
		if title_font:
			sub.add_theme_font_override("font", title_font)
		add_child(sub)
		_place(sub, Rect2(-400, -30, 800, 44))
		_fade_in(sub, 0.35)


# ==================================== BUTTONS =================================
func _build_buttons() -> void:
	var size := Vector2(480, 92)
	_start_button = Button.new()
	_start_button.text = "Start"
	_start_button.add_theme_font_size_override("font_size", 58)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_start_button.add_theme_color_override(color_name, Color.WHITE)
	_start_button.add_theme_color_override("font_outline_color", RED_DARK)
	_start_button.add_theme_constant_override("outline_size", 8)
	for state in ["normal", "hover", "pressed", "focus"]:
		_start_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if title_font:
		_start_button.add_theme_font_override("font", title_font)
	_start_button.pressed.connect(_on_start_pressed)
	add_child(_start_button)
	_place(_start_button, Rect2(-size.x * 0.5, 170, size.x, size.y))

	# hexagon art drawn behind the button's text
	var border := _poly_to(_start_button, _hex(Vector2(-5, -5), size + Vector2(10, 10)), RED_DARK)
	_start_body = _poly_to(_start_button, _hex(Vector2.ZERO, size), RED)
	var shine := _poly_to(_start_button, PackedVector2Array([
		Vector2(size.y * 0.5, 0), Vector2(size.x - size.y * 0.5, 0),
		Vector2(size.x, size.y * 0.5), Vector2(0, size.y * 0.5)]), Color(1, 1, 1, 0.14))
	border.show_behind_parent = true
	_start_body.show_behind_parent = true
	shine.show_behind_parent = true
	for x in [size.x * 0.115, size.x * 0.885]:
		var gem := ColorRect.new()
		gem.color = CREAM
		gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gem.show_behind_parent = true
		_start_button.add_child(gem)
		gem.size = Vector2(16, 16)
		gem.position = Vector2(x - 8.0, size.y * 0.5 - 8.0)
		gem.pivot_offset = gem.size * 0.5
		gem.rotation_degrees = 45.0
	_start_button.mouse_entered.connect(func(): _start_body.color = RED_LIGHT)
	_start_button.mouse_exited.connect(func(): _start_body.color = RED)
	_start_button.focus_entered.connect(func(): _start_body.color = RED_LIGHT)
	_start_button.focus_exited.connect(func(): _start_body.color = RED)
	_start_body.color = RED_LIGHT                  # focused from the start
	_wire_hover(_start_button, 1.06)
	_fade_in(_start_button, 1.0)

	_quit_button = Button.new()
	_quit_button.text = "Quit"
	_quit_button.focus_mode = Control.FOCUS_NONE
	_quit_button.add_theme_font_size_override("font_size", 26)
	_quit_button.add_theme_color_override("font_color", Color.WHITE)
	_quit_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_quit_button.add_theme_color_override("font_pressed_color", Color("dff3ff"))
	_quit_button.add_theme_color_override("font_outline_color", Color("1f5f9a"))
	_quit_button.add_theme_constant_override("outline_size", 6)
	_quit_button.add_theme_stylebox_override("normal", _box(Color(0.1, 0.3, 0.6, 0.35), Color(1, 1, 1, 0.6), 2, 24, false))
	_quit_button.add_theme_stylebox_override("hover", _box(Color(0.1, 0.3, 0.6, 0.6), Color.WHITE, 2, 24, false))
	_quit_button.add_theme_stylebox_override("pressed", _box(Color(0.1, 0.3, 0.6, 0.8), Color.WHITE, 2, 24, false))
	_quit_button.pressed.connect(_on_quit_pressed)
	add_child(_quit_button)
	_place(_quit_button, Rect2(-100, 290, 200, 52))
	_wire_hover(_quit_button, 1.05)
	_fade_in(_quit_button, 1.15)
	if OS.has_feature("web"):                # no "quit" in a browser
		_quit_button.hide()

	var hint := Label.new()
	hint.text = "Press Enter to start"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hint.add_theme_color_override("font_outline_color", Color("1f5f9a"))
	hint.add_theme_constant_override("outline_size", 5)
	add_child(hint)
	_place(hint, Rect2(-300, 360, 600, 30))
	_fade_in(hint, 1.3)


func _hex(pos: Vector2, s: Vector2) -> PackedVector2Array:
	var inset := s.y * 0.5
	return PackedVector2Array([
		pos + Vector2(inset, 0), pos + Vector2(s.x - inset, 0), pos + Vector2(s.x, s.y * 0.5),
		pos + Vector2(s.x - inset, s.y), pos + Vector2(inset, s.y), pos + Vector2(0, s.y * 0.5)])


func _wire_hover(b: Button, grown: float) -> void:
	b.mouse_entered.connect(func(): _scale_to(b, grown))
	b.mouse_exited.connect(func(): _scale_to(b, 1.0))


func _scale_to(c: Control, s: float) -> void:
	var old: Tween = c.get_meta("scale_tween", null)
	if old:
		old.kill()
	var t := create_tween()
	c.set_meta("scale_tween", t)
	t.tween_property(c, "scale", Vector2(s, s), 0.12).set_trans(Tween.TRANS_SINE)


# ===================================== FADES ==================================
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)                          # added last = drawn on top of everything
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "color:a", 0.0, 0.7)


func _fade_in(node: CanvasItem, delay: float) -> void:
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.6).set_delay(delay)


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


func _poly(points: PackedVector2Array, color: Color) -> Polygon2D:
	return _poly_to(self, points, color)


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
