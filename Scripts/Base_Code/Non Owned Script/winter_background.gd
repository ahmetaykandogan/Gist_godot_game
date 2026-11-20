extends CanvasLayer
## Chinese ink-wash (shan-shui) winter background for the game scene.
## Sits on a CanvasLayer BEHIND everything (layer -100), so it doesn't matter
## how main.tscn is built. It rebuilds itself if the window is resized.
## Everything is drawn in code: layered misty mountains, a snowy great peak,
## a pagoda and a small hall, pines, a flock of birds, a plum-blossom branch
## in the corner, drifting mist and falling snow.

@export var dim := 0.10                  # 0..1, darkens the scenery a bit so cards stay readable
@export var show_sun := true             # pale sun/moon disc in the sky
@export var show_pagoda := true
@export var show_birds := true
@export var show_blossom := true         # plum-blossom branch in the top-right corner
@export var snowfall := true

const SKY_TOP := Color("c3d1dc")
const SKY_BOTTOM := Color("f1f0ea")
const INK := [Color("c9d8e6"), Color("a9c0d8"), Color("7f9fc2"), Color("5b7ea8")]  # far -> near
const PEAK := Color("8fa9c8")
const SNOW := Color("f6f9fc")
const SNOW_SHADE := Color("d3deea")
const PINE := Color("34506f")
const PINE_FAR := Color("6f89a8")
const WALL := Color("d9e1ea")
const WOOD := Color("3b3a45")
const ROOF := Color("3e5373")
const BRANCH := Color("3a2f33")
const BLOSSOM := Color("e0707f")
const BLOSSOM_LIGHT := Color("f2a3ad")
const BLOSSOM_CORE := Color("9e3347")
const BIRD := Color("3d4f6a")

var _root: Control
var _vp := Vector2(1920, 1080)
var _time := 0.0
var _mists: Array[Dictionary] = []
var _birds: Array[Dictionary] = []
var _sun: Node2D
var _sun_base := Vector2.ZERO
var _branch: Node2D
var _rng := RandomNumberGenerator.new()


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
	for m in _mists:
		var node: Control = m["node"]
		node.position.x += float(m["speed"]) * delta
		if node.position.x > _vp.x + 50.0:
			node.position.x = -node.size.x
	for b in _birds:
		var bn: Node2D = b["node"]
		bn.position.x += float(b["speed"]) * delta
		bn.position.y = float(b["base_y"]) + sin(_time * 1.1 + float(b["phase"])) * 5.0
		bn.scale.y = 0.65 + 0.35 * absf(sin(_time * 3.0 + float(b["phase"])))
		if bn.position.x < -80.0:
			bn.position.x = _vp.x + 80.0
	if _sun:
		_sun.position = _sun_base + Vector2(0, sin(_time * 0.3) * 6.0)
		_sun.modulate.a = 0.9 + 0.1 * sin(_time * 0.4)
	if _branch:
		_branch.rotation = sin(_time * 0.5) * 0.012


func _rebuild() -> void:
	for child in _root.get_children():
		child.queue_free()
	_mists.clear()
	_birds.clear()
	_sun = null
	_branch = null
	_build()


func _build() -> void:
	_vp = get_viewport().get_visible_rect().size
	var vp := _vp
	var k := vp.y / 1080.0
	_rng.seed = 20261120   # fixed seed: the landscape looks the same on every rebuild

	# sky: pale rice-paper gradient
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

	# pale sun / moon with a soft halo
	if show_sun:
		_sun = Node2D.new()
		_root.add_child(_sun)
		_sun_base = vp * Vector2(0.30, 0.17)
		_sun.position = _sun_base
		var halo := Sprite2D.new()
		halo.texture = _radial(Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0), 0.0)
		halo.scale = Vector2.ONE * (700.0 * k / 256.0)
		_sun.add_child(halo)
		_poly_to(_sun, _circle(Vector2.ZERO, 62.0 * k, 28), Color(0.98, 0.88, 0.84, 0.9))

	# far ridge, haze, second ridge
	_ridge(0.50, 0.24, 2.2, INK[0], Color("eef3f8"), 0.03)
	_haze(0.36, 0.22, 0.55)
	_ridge(0.62, 0.28, 1.7, INK[1], Color("f2f6fa"), 0.05)
	_mist_blobs([[0.10, 0.50, 900.0, 200.0, 0.55, 6.0], [0.60, 0.46, 1100.0, 240.0, 0.45, 4.0]], k)

	# the great snowy peak on the right
	_great_peak(vp.x * 0.84, vp.y * 0.76, vp.x * 0.36, vp.y * 0.66, PEAK, SNOW, Color("c4d3e4"))
	_haze(0.52, 0.20, 0.60)

	# mid ridge
	_ridge(0.78, 0.22, 1.4, INK[2], SNOW_SHADE, 0.045)
	_mist_blobs([[0.30, 0.68, 1000.0, 200.0, 0.55, 8.0], [0.85, 0.72, 800.0, 180.0, 0.45, 5.0]], k)

	# rock + pagoda on the right
	if show_pagoda:
		var rock_w := 380.0 * k
		var rock_h := 150.0 * k
		var rock_base := Vector2(vp.x * 0.70, vp.y * 0.81)
		_rock(rock_base, rock_w, rock_h)
		_pagoda(rock_base + Vector2(0, -rock_h * 0.92), 300.0 * k, 4)
		# pines clinging to the rock
		_pine(rock_base + Vector2(-rock_w * 0.38, -rock_h * 0.3), 120.0 * k, PINE_FAR)
		_pine(rock_base + Vector2(rock_w * 0.40, -rock_h * 0.3), 140.0 * k, PINE_FAR)
		_pine(rock_base + Vector2(rock_w * 0.52, -rock_h * 0.1), 100.0 * k, PINE_FAR)
	_haze(0.66, 0.16, 0.50)

	# small hall bottom-left (drawn before the front hills so snow covers its base)
	_hill(0.80, 0.012, 0.004, 0.5, SNOW_SHADE)
	if show_pagoda:
		_pagoda(Vector2(vp.x * 0.17, vp.y * 0.835), 150.0 * k, 2, 1.9)

	# back pines at the edges
	var trees: Array = [[0.04, 0.84, 190.0], [0.10, 0.82, 140.0], [0.90, 0.85, 170.0], [0.96, 0.83, 220.0], [0.27, 0.81, 100.0], [0.52, 0.80, 80.0]]
	for t in trees:
		_pine(Vector2(float(t[0]) * vp.x, float(t[1]) * vp.y), float(t[2]) * k)

	# front snowy hills
	_hill(0.88, 0.02, 0.003, 2.0, SNOW_SHADE)
	_hill(0.875, 0.02, 0.003, 2.0, SNOW)

	# birds
	if show_birds:
		var flock: Array = [[0.62, 0.20], [0.65, 0.17], [0.68, 0.22], [0.70, 0.18], [0.73, 0.24], [0.66, 0.26], [0.75, 0.20]]
		for f in flock:
			_bird(Vector2(float(f[0]) * vp.x, float(f[1]) * vp.y), (7.0 + _rng.randf() * 5.0) * k, -(18.0 + _rng.randf() * 8.0) * k)

	# plum-blossom branch in the corner: the only red accent
	if show_blossom:
		_blossom_branch(k)

	# snowfall
	if snowfall:
		var p := CPUParticles2D.new()
		p.texture = _radial(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.0, 32)
		p.amount = 130
		p.lifetime = 14.0
		p.preprocess = 14.0
		p.position = Vector2(vp.x * 0.5, -20.0)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(vp.x * 0.6, 10.0)
		p.direction = Vector2(0.15, 1.0)
		p.spread = 12.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = 35.0
		p.initial_velocity_max = 90.0
		p.scale_amount_min = 0.12
		p.scale_amount_max = 0.38
		p.color = Color(1, 1, 1, 0.9)
		_root.add_child(p)

	# slight darkening so the cards on the table stand out
	if dim > 0.0:
		var shade := ColorRect.new()
		shade.color = Color(0.08, 0.12, 0.2, dim)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(shade)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ================================== PIECES ====================================
## Mountain ridge from layered sine waves. 1 - |sin| gives sharp peaks.
## A lighter "snow" copy sits under a darker body shifted down (thicker on high peaks).
func _ridge(base_ratio: float, amp_ratio: float, cycles: float, color: Color, cap_color: Color, cap_depth: float) -> void:
	var ph1 := _rng.randf() * TAU
	var ph2 := _rng.randf() * TAU
	var ph3 := _rng.randf() * TAU
	var top := PackedVector2Array()
	var body := PackedVector2Array()
	var base := _vp.y * base_ratio
	var amp := _vp.y * amp_ratio
	var x := -20.0
	while x <= _vp.x + 20.0:
		var u := x / _vp.x
		var h := 0.55 * (1.0 - absf(sin(u * PI * cycles + ph1)))
		h += 0.30 * (1.0 - absf(sin(u * PI * cycles * 2.3 + ph2)))
		h += 0.15 * (1.0 - absf(sin(u * PI * cycles * 5.1 + ph3)))
		top.append(Vector2(x, base - h * amp))
		body.append(Vector2(x, base - h * amp + cap_depth * _vp.y * (0.25 + 0.75 * h)))
		x += 12.0
	top.append(Vector2(_vp.x + 20.0, _vp.y))
	top.append(Vector2(-20.0, _vp.y))
	body.append(Vector2(_vp.x + 20.0, _vp.y))
	body.append(Vector2(-20.0, _vp.y))
	_poly(top, cap_color)
	_poly(body, color)


## One tall, dramatic snowy peak with a lit left side and a shaded right side.
func _great_peak(cx: float, base: float, w: float, h: float, color: Color, cap: Color, shade: Color) -> void:
	var steps := 10
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var y := base - h * t
		var half := w * 0.5 * pow(1.0 - t, 0.85)
		var jl := _rng.randf_range(-0.03, 0.03) * w * (1.0 - t)
		var jr := _rng.randf_range(-0.03, 0.03) * w * (1.0 - t)
		left.append(Vector2(cx - half + jl, y))
		right.append(Vector2(cx + half + jr, y))
	# body
	var body := PackedVector2Array()
	for p in left:
		body.append(p)
	for i in range(steps - 1, -1, -1):
		body.append(right[i])
	_poly(body, color)
	# snow cap with a ragged lower edge
	var i0 := 4
	var capp := PackedVector2Array()
	for i in range(i0, steps + 1):
		capp.append(left[i])
	for i in range(steps - 1, i0 - 1, -1):
		capp.append(right[i])
	var a: Vector2 = right[i0]
	var b: Vector2 = left[i0]
	for j in range(1, 4):
		var pt := a.lerp(b, float(j) / 4.0)
		pt.y += (h * 0.07) if j % 2 == 1 else -h * 0.02
		capp.append(pt)
	_poly(capp, cap)
	# shaded right side of the snow
	var sh := PackedVector2Array()
	sh.append(left[steps])
	for i in range(steps - 1, i0 - 1, -1):
		sh.append(right[i])
	sh.append(Vector2(cx + w * 0.04, base - h * 0.42))
	sh.append(Vector2(cx - w * 0.01, base - h * 0.66))
	_poly(sh, shade)


func _rock(base: Vector2, w: float, h: float) -> void:
	_poly(PackedVector2Array([
		base + Vector2(-w * 0.5, 0), base + Vector2(-w * 0.42, -h * 0.5),
		base + Vector2(-w * 0.25, -h * 0.85), base + Vector2(-w * 0.05, -h),
		base + Vector2(w * 0.2, -h * 0.9), base + Vector2(w * 0.4, -h * 0.5),
		base + Vector2(w * 0.5, 0)]), INK[3])
	_poly(PackedVector2Array([
		base + Vector2(-w * 0.25, -h * 0.85), base + Vector2(-w * 0.05, -h),
		base + Vector2(w * 0.2, -h * 0.9), base + Vector2(w * 0.1, -h * 0.78),
		base + Vector2(-w * 0.05, -h * 0.82), base + Vector2(-w * 0.2, -h * 0.74)]), SNOW)


## Chinese pagoda: stacked tiers, each with a wall, a dark door and an upturned snowy roof.
## `wide` makes it broader (used for the low hall).
func _pagoda(base: Vector2, s: float, tiers: int, wide: float = 1.0) -> void:
	var cx := base.x
	for i in tiers:
		var yb := base.y - i * s * 0.22
		var bw := s * (0.16 - 0.022 * i) * wide
		var bh := s * 0.11
		var rw := bw + s * 0.075 * wide
		var roof_h := s * 0.09
		var y0 := yb - bh
		# wall
		_poly(PackedVector2Array([
			Vector2(cx - bw, yb), Vector2(cx - bw, y0),
			Vector2(cx + bw, y0), Vector2(cx + bw, yb)]), WALL)
		# door
		_poly(PackedVector2Array([
			Vector2(cx - bw * 0.22, yb), Vector2(cx - bw * 0.22, yb - bh * 0.62),
			Vector2(cx + bw * 0.22, yb - bh * 0.62), Vector2(cx + bw * 0.22, yb)]), WOOD)
		# roof with upturned corners
		_poly(PackedVector2Array([
			Vector2(cx - rw, y0 - s * 0.045),
			Vector2(cx - rw * 0.82, y0 + s * 0.008),
			Vector2(cx - rw * 0.42, y0 - roof_h * 0.45),
			Vector2(cx - rw * 0.17, y0 - roof_h),
			Vector2(cx + rw * 0.17, y0 - roof_h),
			Vector2(cx + rw * 0.42, y0 - roof_h * 0.45),
			Vector2(cx + rw * 0.82, y0 + s * 0.008),
			Vector2(cx + rw, y0 - s * 0.045),
			Vector2(cx + rw * 0.84, y0 + s * 0.038),
			Vector2(cx - rw * 0.84, y0 + s * 0.038)]), ROOF)
		# snow on the roof
		_poly(PackedVector2Array([
			Vector2(cx - rw * 0.42, y0 - roof_h * 0.45),
			Vector2(cx - rw * 0.17, y0 - roof_h),
			Vector2(cx + rw * 0.17, y0 - roof_h),
			Vector2(cx + rw * 0.42, y0 - roof_h * 0.45),
			Vector2(cx + rw * 0.2, y0 - roof_h * 0.55),
			Vector2(cx, y0 - roof_h * 0.6),
			Vector2(cx - rw * 0.2, y0 - roof_h * 0.55)]), SNOW)
	# spire
	var top_y := base.y - (tiers - 1) * s * 0.22 - s * 0.11 - s * 0.09
	_line_to(_root, [Vector2(cx, top_y), Vector2(cx, top_y - s * 0.22)], maxf(2.0, s * 0.012), WOOD)


func _pine(base: Vector2, s: float, col: Color = PINE) -> void:
	_poly(PackedVector2Array([
		base + Vector2(-s * 0.06, 0), base + Vector2(s * 0.06, 0),
		base + Vector2(s * 0.06, -s * 0.2), base + Vector2(-s * 0.06, -s * 0.2)]), Color("4a3a3a"))
	for i in 3:
		var apex := base + Vector2(0, -s * 1.15 + i * s * 0.3)
		var half := s * (0.26 + 0.12 * i)
		var bottom := apex.y + s * 0.55
		_poly(PackedVector2Array([apex, Vector2(apex.x + half, bottom), Vector2(apex.x - half, bottom)]), col)
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


## Static horizontal haze band (transparent -> light -> transparent).
func _haze(y_ratio: float, h_ratio: float, alpha: float) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.96, 0.97, 0.0))
	g.set_color(1, Color(0.95, 0.96, 0.97, 0.0))
	g.add_point(0.5, Color(0.95, 0.96, 0.97, alpha))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.5, 0.0)
	t.fill_to = Vector2(0.5, 1.0)
	t.width = 8
	t.height = 128
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(r)
	r.position = Vector2(0, _vp.y * y_ratio)
	r.size = Vector2(_vp.x, _vp.y * h_ratio)


## Drifting mist blobs: [x ratio, y ratio, width, height, alpha, speed].
func _mist_blobs(data: Array, k: float) -> void:
	for d in data:
		var r := TextureRect.new()
		r.texture = _radial(Color(0.96, 0.97, 0.98, 1.0), Color(0.96, 0.97, 0.98, 0.0), 0.0)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.modulate.a = float(d[4])
		_root.add_child(r)
		r.size = Vector2(float(d[2]), float(d[3])) * k
		r.position = Vector2(float(d[0]) * _vp.x - r.size.x * 0.5, float(d[1]) * _vp.y - r.size.y * 0.5)
		_mists.append({"node": r, "speed": float(d[5]) * k})


func _bird(pos: Vector2, s: float, speed: float) -> void:
	var n := Node2D.new()
	_root.add_child(n)
	n.position = pos
	_line_to(n, [Vector2(-s, 0), Vector2(-s * 0.5, -s * 0.35), Vector2(0, 0), Vector2(s * 0.5, -s * 0.35), Vector2(s, 0)], 2.0, BIRD)
	_birds.append({"node": n, "speed": speed, "base_y": pos.y, "phase": _rng.randf() * TAU})


## Plum-blossom branch hanging from the top-right corner.
func _blossom_branch(k: float) -> void:
	_branch = Node2D.new()
	_root.add_child(_branch)
	_branch.position = Vector2(_vp.x + 20.0 * k, -20.0 * k)
	_branch.scale = Vector2(k, k)
	_line_to(_branch, [Vector2(0, 0), Vector2(-110, 70), Vector2(-250, 105), Vector2(-390, 190), Vector2(-540, 225)], 9.0, BRANCH)
	_line_to(_branch, [Vector2(-110, 70), Vector2(-140, 190), Vector2(-120, 290)], 5.0, BRANCH)
	_line_to(_branch, [Vector2(-250, 105), Vector2(-300, 40), Vector2(-390, 20)], 4.0, BRANCH)
	_line_to(_branch, [Vector2(-390, 190), Vector2(-420, 290), Vector2(-400, 360)], 4.0, BRANCH)
	_line_to(_branch, [Vector2(-540, 225), Vector2(-600, 290)], 3.0, BRANCH)
	# flowers: [x, y, radius]
	var flowers: Array = [
		[-120, 72, 16], [-250, 104, 18], [-330, 60, 14], [-390, 22, 16], [-300, 40, 12],
		[-140, 190, 15], [-122, 290, 17], [-390, 188, 18], [-420, 290, 14], [-402, 360, 16],
		[-540, 225, 19], [-600, 290, 15], [-470, 205, 13], [-200, 92, 12]]
	for f in flowers:
		_flower(_branch, Vector2(float(f[0]), float(f[1])), float(f[2]))
	# buds
	for bpos in [Vector2(-170, 140), Vector2(-350, 120), Vector2(-450, 250), Vector2(-500, 180)]:
		_poly_to(_branch, _circle(bpos, 7.0, 10), BLOSSOM_LIGHT)


func _flower(parent: Node, pos: Vector2, r: float) -> void:
	for i in 5:
		var a := TAU * float(i) / 5.0 - PI * 0.5
		var c := pos + Vector2(cos(a), sin(a)) * r * 0.55
		_poly_to(parent, _circle(c, r * 0.55, 10), BLOSSOM if i % 2 == 0 else BLOSSOM_LIGHT)
	_poly_to(parent, _circle(pos, r * 0.28, 10), BLOSSOM_CORE)


# ================================== HELPERS ===================================
func _poly(points: PackedVector2Array, color: Color) -> Polygon2D:
	return _poly_to(_root, points, color)


func _poly_to(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	parent.add_child(p)
	return p


func _line_to(parent: Node, pts: Array, width: float, color: Color) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array(pts)
	l.width = width
	l.default_color = color
	l.antialiased = true
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(l)
	return l


func _circle(c: Vector2, r: float, n: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


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
