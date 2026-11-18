extends CanvasLayer
## Winter background for the game scene (same style as the start screen).
## Sits on a CanvasLayer BEHIND everything (layer -100), so it doesn't matter
## how main.tscn is built. It rebuilds itself if the window is resized.

@export var dim := 0.12                  # 0..1, darkens the scenery a bit so cards stay readable
@export var show_crystal := true
@export var snowfall := true

const SKY_TOP := Color("2c9be6")
const SKY_BOTTOM := Color("aedff9")
const MOUNTAIN_FAR := Color("86bdea")
const MOUNTAIN_MID := Color("5f9bd8")
const SNOW := Color("f4fbff")
const SNOW_SHADE := Color("c4def0")
const PINE := Color("2d7388")

var _root: Control
var _vp := Vector2(1920, 1080)
var _time := 0.0
var _clouds: Array[Dictionary] = []
var _crystal: Node2D
var _crystal_base := Vector2.ZERO


func _ready() -> void:
	layer = -100
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	get_viewport().size_changed.connect(_rebuild)


func _process(delta: float) -> void:
	_time += delta
	for c in _clouds:
		var node: Control = c["node"]
		node.position.x += float(c["speed"]) * delta
		if node.position.x > _vp.x + 50.0:
			node.position.x = -400.0
	if _crystal:
		_crystal.position = _crystal_base + Vector2(0, sin(_time * 1.2) * 12.0)
		_crystal.rotation = sin(_time * 0.7) * 0.04


func _rebuild() -> void:
	for child in _root.get_children():
		child.queue_free()
	_clouds.clear()
	_crystal = null
	_build()


func _build() -> void:
	_vp = get_viewport().get_visible_rect().size
	var vp := _vp
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
	_root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# soft light in the middle
	var glow := TextureRect.new()
	glow.texture = _radial(Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0), 0.0)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(glow)
	glow.size = Vector2(1600, 1100) * k
	glow.position = vp * Vector2(0.5, 0.4) - glow.size * 0.5

	# clouds
	var cloud_data: Array = [[0.06, 0.07, 1.0, 7.0], [0.55, 0.04, 1.2, 5.0], [0.84, 0.16, 0.8, 9.0]]
	for c in cloud_data:
		_add_cloud(Vector2(float(c[0]) * vp.x, float(c[1]) * vp.y), float(c[2]) * k, float(c[3]))

	# mountains: [centre x, base y, width, height] as fractions of the screen
	var far: Array = [[0.12, 0.62, 0.28, 0.22], [0.38, 0.62, 0.34, 0.28], [0.62, 0.62, 0.40, 0.34], [0.86, 0.62, 0.30, 0.24]]
	for m in far:
		_mountain(m, MOUNTAIN_FAR, Color("f2faff"))
	var mid: Array = [[0.20, 0.70, 0.40, 0.18], [0.52, 0.70, 0.46, 0.22], [0.88, 0.70, 0.40, 0.20]]
	for m in mid:
		_mountain(m, MOUNTAIN_MID, Color("eaf6ff"))

	# back hill, trees, front hills
	_hill(0.74, 0.014, 0.004, 0.5, SNOW_SHADE)
	_hill(0.735, 0.014, 0.004, 0.5, Color("e3f2fc"))
	var trees: Array = [[0.04, 0.76, 190.0], [0.10, 0.74, 140.0], [0.90, 0.75, 170.0], [0.96, 0.73, 220.0], [0.20, 0.73, 100.0], [0.80, 0.73, 110.0]]
	for t in trees:
		_pine(Vector2(float(t[0]) * vp.x, float(t[1]) * vp.y), float(t[2]) * k)
	_hill(0.86, 0.02, 0.003, 2.0, SNOW_SHADE)
	_hill(0.85, 0.02, 0.003, 2.0, SNOW)

	# floating crystal
	if show_crystal:
		_crystal = Node2D.new()
		_root.add_child(_crystal)
		_crystal_base = vp * Vector2(0.86, 0.2)
		_crystal.position = _crystal_base
		_crystal.scale = Vector2(k, k) * 0.8
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

	# snowfall
	if snowfall:
		var p := CPUParticles2D.new()
		p.texture = _radial(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.0, 32)
		p.amount = 110
		p.lifetime = 14.0
		p.preprocess = 14.0
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
		_root.add_child(p)

	# slight darkening so the cards on the table stand out
	if dim > 0.0:
		var shade := ColorRect.new()
		shade.color = Color(0.05, 0.1, 0.25, dim)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(shade)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ================================== PIECES ====================================
func _add_cloud(pos: Vector2, s: float, speed: float) -> void:
	var cloud := Control.new()
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud.modulate.a = 0.9
	_root.add_child(cloud)
	cloud.position = pos
	cloud.scale = Vector2(s, s)
	var parts: Array = [Rect2(0, 30, 320, 70), Rect2(40, 0, 140, 100), Rect2(160, 12, 120, 80)]
	for r: Rect2 in parts:
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.85)
		sb.set_corner_radius_all(50)
		panel.add_theme_stylebox_override("panel", sb)
		cloud.add_child(panel)
		panel.position = r.position
		panel.size = r.size
	_clouds.append({"node": cloud, "speed": speed})


func _mountain(m: Array, body: Color, cap: Color) -> void:
	var cx: float = float(m[0]) * _vp.x
	var base: float = float(m[1]) * _vp.y
	var w: float = float(m[2]) * _vp.x
	var h: float = float(m[3]) * _vp.y
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


func _hill(base_ratio: float, amp_ratio: float, freq: float, phase: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= _vp.x + 40.0:
		pts.append(Vector2(x, _vp.y * base_ratio + sin(x * freq + phase) * _vp.y * amp_ratio))
		x += 40.0
	pts.append(Vector2(_vp.x + 40.0, _vp.y))
	pts.append(Vector2(0, _vp.y))
	_poly(pts, color)


# ================================== HELPERS ===================================
func _poly(points: PackedVector2Array, color: Color) -> Polygon2D:
	return _poly_to(_root, points, color)


func _poly_to(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	parent.add_child(p)
	return p


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
