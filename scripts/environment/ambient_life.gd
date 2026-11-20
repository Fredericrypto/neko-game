extends Node2D
## Vida ambiental sutil, toda movida por um único vento compartilhado:
## antenas, fios, planta, ventilador e folhas caindo. Poucos elementos, bem feitos.

var t := 0.0
var wind := 0.0
var gust := 0.0
var leaves: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

const MASTS: Array = [[300.0, 640.0, 150.0], [950.0, 560.0, 110.0], [1500.0, 700.0, 130.0], [2020.0, 520.0, 120.0], [2850.0, 760.0, 150.0]]
const WIRES: Array = [[0, 1, 40.0], [1, 2, 55.0], [3, 4, 80.0]]

func _ready() -> void:
	_rng.seed = 77
	for i in 6:
		leaves.append(_new_leaf(true))

func _new_leaf(anywhere: bool) -> Dictionary:
	var cam := get_viewport().get_camera_2d()
	var c := cam.get_screen_center_position() if cam else Vector2(640, 500)
	return {
		"p": Vector2(c.x + _rng.randf_range(-700.0, 700.0), c.y + (_rng.randf_range(-380.0, 380.0) if anywhere else -400.0)),
		"ph": _rng.randf() * TAU, "sp": _rng.randf_range(34.0, 52.0), "rot": _rng.randf() * TAU,
		"tone": [Palette.MID, Palette.CHARCOAL, Palette.MID][_rng.randi() % 3], "sz": _rng.randf_range(6.0, 9.0),
	}

func _process(delta: float) -> void:
	t += delta
	gust = maxf(0.0, sin(t * 0.37) * sin(t * 0.91 + 1.3))
	wind = 0.45 + gust * 0.55
	var cam := get_viewport().get_camera_2d()
	var c := cam.get_screen_center_position() if cam else Vector2(640, 500)
	for l in leaves:
		l["p"] += Vector2(wind * 26.0 + sin(t * 1.6 + l["ph"]) * 22.0, l["sp"]) * delta
		l["rot"] += (1.3 + wind) * delta
		if l["p"].y > c.y + 400.0 or l["p"].x > c.x + 760.0:
			var nl := _new_leaf(false)
			for key in nl:
				l[key] = nl[key]
	queue_redraw()

func _mast_top(i: int) -> Vector2:
	var m: Array = MASTS[i]
	var sway := sin(t * 1.7 + float(i)) * (1.5 + wind * 3.0)
	return Vector2(m[0] + sway, m[1] - m[2])

func _draw() -> void:
	for i in MASTS.size():
		var m: Array = MASTS[i]
		var base := Vector2(m[0], m[1])
		var top := _mast_top(i)
		draw_line(base, top, Palette.CHARCOAL, 3.5, true)
		for k in 3:
			var f := 0.45 + k * 0.17
			var p := base.lerp(top, f)
			var w := 26.0 - k * 7.0
			draw_line(p + Vector2(-w, 0.0), p + Vector2(w, 0.0), Palette.CHARCOAL, 2.5, true)
	for w in WIRES:
		var a := _mast_top(w[0]) + Vector2(0, 6)
		var b := _mast_top(w[1]) + Vector2(0, 6)
		var sag: float = w[2] + sin(t * 1.1) * 4.0 * wind
		var pts := PackedVector2Array()
		for s in 21:
			var k := float(s) / 20.0
			pts.append(a.lerp(b, k) + Vector2(0.0, sin(k * PI) * sag))
		draw_polyline(pts, Palette.INK, 1.6, true)
	_plant()
	_fan()
	for l in leaves:
		_leaf(l)

func _plant() -> void:
	var base := Vector2(470.0, 640.0)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-16, -30), base + Vector2(16, -30), base + Vector2(12, 0), base + Vector2(-12, 0)]), Palette.CHARCOAL)
	draw_rect(Rect2(base.x - 18.0, base.y - 34.0, 36.0, 6.0), Palette.WARM)
	for i in 6:
		var a := -PI / 2.0 + (i - 2.5) * 0.46 + sin(t * 1.9 + i) * 0.05 * (0.4 + wind)
		var len := 46.0 + (i % 3) * 9.0
		var o := base + Vector2(0.0, -32.0)
		var dir := Vector2.from_angle(a)
		var nrm := dir.orthogonal()
		var bend := nrm * (sin(t * 2.0 + i) * 3.0 * wind + (i - 2.5) * 2.0)
		var blade := PackedVector2Array([o + nrm * 4.0, o + dir * len * 0.55 + nrm * 8.0 + bend * 0.5, o + dir * len + bend, o + dir * len * 0.55 - nrm * 8.0 + bend * 0.5, o - nrm * 4.0])
		draw_colored_polygon(blade, Palette.CHARCOAL if i % 2 == 0 else Palette.INK)
		draw_line(o, o + dir * len * 0.9 + bend * 0.9, Palette.MID, 1.2, true)

func _fan() -> void:
	var c := Vector2(2700.0, 716.0)
	draw_colored_polygon(_flat_ell(c, 30.0, 7.0), Palette.INK)
	for i in 3:
		var a := t * (3.2 + wind * 2.0) + i * TAU / 3.0
		draw_line(c, c + Vector2(cos(a) * 28.0, sin(a) * 6.0), Palette.WARM, 4.0, true)
	draw_circle(c, 4.0, Palette.MID)

func _flat_ell(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _leaf(l: Dictionary) -> void:
	var p: Vector2 = l["p"]
	var r: float = l["rot"]
	var s: float = l["sz"]
	var squeeze := 0.35 + 0.65 * absf(cos(r * 0.8))
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		var rr := s * (1.0 + 0.35 * cos(a * 2.0))
		pts.append(p + Vector2(cos(a) * rr, sin(a) * rr * 0.45 * squeeze).rotated(r))
	draw_colored_polygon(pts, l["tone"])
	draw_line(p + Vector2(-s, 0).rotated(r), p + Vector2(s, 0).rotated(r), Palette.IVORY, 1.0, true)
