extends Node2D
## Fachadas e estruturas estáticas, desenhadas uma única vez a partir dos dados do nível.
## Materiais distinguíveis só por valor tonal, geometria e textura de linhas (sem filtro).

const VIEW := Rect2(-340.0, 100.0, 3600.0, 1040.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_alleys()
	for s in RooftopLevel.SOLIDS:
		var r := Rect2(s[0], s[1], s[2], s[3]).intersection(VIEW)
		match s[4]:
			RooftopLevel.SKIN_STONE: _stone(r)
			RooftopLevel.SKIN_INK: _ink(r)
			RooftopLevel.SKIN_CHARCOAL: _charcoal(r)
			RooftopLevel.SKIN_MID: _mid(r)
			"vent": _vent(r)
			"ac": _ac(r)
			"crate": _crate(r)
			"house": _house(r)
			"fanbox": _fanbox(r)
	_railings()
	for o in RooftopLevel.ONEWAYS:
		var n: String = o[3]
		if n.begins_with("esc_"):
			_fire_escape(Rect2(o[0], o[1], o[2], 10.0))
		elif n.begins_with("S2"):
			_pipe(Rect2(o[0], o[1], o[2], 10.0))
		elif n.begins_with("P1"):
			_ledge(Rect2(o[0], o[1], o[2], 10.0))
		else:
			_gantry(Rect2(o[0], o[1], o[2], 10.0))
	_water_tower()

func _lip(r: Rect2) -> void:
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5.0), Palette.WARM)
	draw_rect(Rect2(r.position.x, r.position.y + 5.0, r.size.x, 2.0), Palette.INK)

func _alleys() -> void:
	_gradient(Rect2(980.0, 700.0, 160.0, 420.0))
	_gradient(Rect2(2040.0, 760.0, 180.0, 360.0))
	for pipe_x in [1004.0, 2064.0]:
		draw_line(Vector2(pipe_x, 760.0), Vector2(pipe_x, 1100.0), Palette.INK, 5.0, true)
	for pipe_x in [2196.0]:
		draw_line(Vector2(pipe_x, 800.0), Vector2(pipe_x, 1100.0), Palette.INK, 5.0, true)

func _gradient(r: Rect2) -> void:
	draw_rect(r, Palette.CHARCOAL)
	var y := r.position.y
	while y < r.end.y:
		var k := (y - r.position.y) / r.size.y
		var th := 5.0 * k
		if th > 0.3:
			draw_rect(Rect2(r.position.x, y, r.size.x, th), Palette.INK)
		y += 5.0

# ---------- materiais ----------
func _stone(r: Rect2) -> void:
	# telhado inicial: laje de tinta + bloco de pedra clara com grade de janelas (referência do conceito)
	draw_rect(r, Palette.WARM)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 78.0), Palette.INK)
	draw_rect(Rect2(r.position.x, r.position.y + 78.0, r.size.x, 5.0), Palette.CHARCOAL)
	_lip(r)
	var x := r.position.x + 30.0
	while x < r.end.x - 60.0:
		_big_window(Rect2(x, r.position.y + 118.0, 96.0, 110.0))
		_big_window(Rect2(x, r.position.y + 268.0, 96.0, 110.0))
		x += 170.0
	for gx in range(int(r.position.x), int(r.end.x), 12):
		for gy in range(int(r.position.y + 410.0), int(r.end.y), 22):
			var h := (gx * 73856093) ^ (gy * 19349663)
			if h % 11 == 0:
				draw_rect(Rect2(gx, gy, 3.0, 2.0), Palette.MID)
	draw_rect(Rect2(r.position.x, r.position.y + 420.0, r.size.x, r.size.y - 420.0), Palette.CHARCOAL)

func _big_window(w: Rect2) -> void:
	draw_rect(w.grow(5.0), Palette.CHARCOAL)
	draw_rect(w, Palette.INK)
	for i in range(1, 3):
		draw_line(Vector2(w.position.x + w.size.x * i / 3.0, w.position.y), Vector2(w.position.x + w.size.x * i / 3.0, w.end.y), Palette.CHARCOAL, 3.0)
	for j in range(1, 3):
		draw_line(Vector2(w.position.x, w.position.y + w.size.y * j / 3.0), Vector2(w.end.x, w.position.y + w.size.y * j / 3.0), Palette.CHARCOAL, 3.0)

func _ink(r: Rect2) -> void:
	draw_rect(r, Palette.INK)
	var px := r.position.x
	while px < r.end.x:
		draw_rect(Rect2(px, r.position.y, 5.0, r.size.y), Palette.CHARCOAL)
		px += 120.0
	var y := r.position.y + 40.0
	while y < r.end.y - 30.0:
		var x := r.position.x + 22.0
		while x < r.end.x - 44.0:
			var lit := (int(x * 3.0 + y * 7.0) % 13) == 0
			draw_rect(Rect2(x, y, 40.0, 52.0), Palette.PAPER if lit else Palette.CHARCOAL)
			draw_rect(Rect2(x, y, 40.0, 52.0), Palette.MID if not lit else Palette.WARM, false, 2.0)
			x += 60.0
		y += 80.0
	_lip(r)

func _charcoal(r: Rect2) -> void:
	draw_rect(r, Palette.CHARCOAL)
	var y := r.position.y + 36.0
	while y < r.end.y - 30.0:
		var x := r.position.x + 20.0
		while x < r.end.x - 60.0:
			draw_rect(Rect2(x, y, 64.0, 44.0), Palette.INK)
			draw_rect(Rect2(x - 2.0, y + 44.0, 68.0, 5.0), Palette.MID)
			x += 96.0
		y += 86.0
	_lip(r)

func _mid(r: Rect2) -> void:
	draw_rect(r, Palette.MID)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 40.0), Palette.CHARCOAL)
	var y := r.position.y + 76.0
	while y < r.end.y - 30.0:
		var x := r.position.x + 28.0
		while x < r.end.x - 50.0:
			draw_rect(Rect2(x, y, 56.0, 62.0), Palette.INK)
			draw_rect(Rect2(x, y, 56.0, 62.0), Palette.WARM, false, 2.0)
			x += 92.0
		y += 104.0
	_lip(r)

func _vent(r: Rect2) -> void:
	draw_rect(r, Palette.CHARCOAL)
	draw_rect(r, Palette.INK, false, 3.0)
	for i in range(1, 7):
		draw_line(Vector2(r.position.x + 12.0, r.position.y + 8.0 + i * 8.0), Vector2(r.end.x - 12.0, r.position.y + 8.0 + i * 8.0), Palette.MID, 3.0)
	draw_rect(Rect2(r.position.x - 3.0, r.position.y - 6.0, r.size.x + 6.0, 8.0), Palette.WARM)
	draw_rect(Rect2(r.end.x - 24.0, r.position.y - 28.0, 14.0, 24.0), Palette.MID)
	draw_rect(Rect2(r.end.x - 28.0, r.position.y - 34.0, 22.0, 8.0), Palette.WARM)

func _ac(r: Rect2) -> void:
	draw_rect(r, Palette.WARM)
	draw_rect(r, Palette.INK, false, 3.0)
	var c := r.position + Vector2(r.size.x * 0.5, r.size.y * 0.5)
	draw_circle(c, minf(r.size.x, r.size.y) * 0.32, Palette.INK)
	draw_circle(c, minf(r.size.x, r.size.y) * 0.22, Palette.CHARCOAL)
	for i in 3:
		var a := i * TAU / 3.0 + 0.4
		draw_line(c, c + Vector2.from_angle(a) * minf(r.size.x, r.size.y) * 0.22, Palette.MID, 2.5, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5.0), Palette.PAPER)

func _crate(r: Rect2) -> void:
	draw_rect(r, Palette.WARM)
	draw_rect(r, Palette.INK, false, 3.0)
	draw_line(r.position + Vector2(4, 4), r.end - Vector2(4, 4), Palette.CHARCOAL, 3.0, true)
	draw_line(Vector2(r.end.x - 4, r.position.y + 4), Vector2(r.position.x + 4, r.end.y - 4), Palette.CHARCOAL, 3.0, true)
	for k in 3:
		draw_line(Vector2(r.position.x, r.position.y + (k + 1) * r.size.y / 4.0), Vector2(r.end.x, r.position.y + (k + 1) * r.size.y / 4.0), Palette.MID, 1.5)

func _house(r: Rect2) -> void:
	draw_rect(r, Palette.PAPER)
	draw_rect(r, Palette.INK, false, 3.0)
	draw_rect(Rect2(r.position.x - 6.0, r.position.y - 8.0, r.size.x + 12.0, 12.0), Palette.INK)
	draw_rect(Rect2(r.position.x - 6.0, r.position.y - 8.0, r.size.x + 12.0, 4.0), Palette.WARM)
	for i in range(1, 5):
		draw_line(Vector2(r.position.x, r.position.y + 16.0 + i * 16.0), Vector2(r.position.x + 24.0, r.position.y + 16.0 + i * 16.0), Palette.WARM, 2.0)

func _fanbox(r: Rect2) -> void:
	draw_rect(r, Palette.CHARCOAL)
	draw_rect(r, Palette.INK, false, 3.0)
	draw_rect(Rect2(r.position.x - 3.0, r.position.y - 5.0, r.size.x + 6.0, 7.0), Palette.WARM)
	for i in range(1, 4):
		draw_line(Vector2(r.position.x + 10.0, r.position.y + 6.0 + i * 8.0), Vector2(r.end.x - 10.0, r.position.y + 6.0 + i * 8.0), Palette.MID, 2.0)

# ---------- estruturas ----------
func _railings() -> void:
	for seg in [[-300.0, 540.0, 640.0], [640.0, 820.0, 640.0], [1140.0, 1290.0, 700.0], [1370.0, 1560.0, 700.0], [1560.0, 2040.0, 520.0], [2220.0, 2300.0, 760.0], [2430.0, 2660.0, 760.0], [2740.0, 2900.0, 760.0]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		var y: float = seg[2]
		draw_line(Vector2(x0, y - 36.0), Vector2(x1, y - 36.0), Palette.CHARCOAL, 2.5, true)
		draw_line(Vector2(x0, y - 18.0), Vector2(x1, y - 18.0), Palette.CHARCOAL, 2.0, true)
		var x := x0
		while x <= x1:
			draw_line(Vector2(x, y), Vector2(x, y - 38.0), Palette.CHARCOAL, 2.5, true)
			x += 42.0

func _fire_escape(p: Rect2) -> void:
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 7.0), Palette.MID)
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 2.0), Palette.WARM)
	draw_line(Vector2(p.position.x, p.position.y + 7.0), Vector2(p.end.x, p.position.y + 7.0), Palette.INK, 1.5)
	var x := p.position.x + 6.0
	while x < p.end.x:
		draw_line(Vector2(x, p.position.y + 7.0), Vector2(x - 8.0, p.position.y + 22.0), Palette.MID, 1.5, true)
		x += 14.0
	var wall_left := p.position.x < 1100.0 or (p.position.x > 2000.0 and p.position.x < 2100.0)
	var ex := p.position.x if wall_left else p.end.x
	draw_line(Vector2(ex, p.position.y), Vector2(ex, p.position.y - 36.0), Palette.WARM, 2.5, true)
	var fx := p.end.x if wall_left else p.position.x
	draw_line(Vector2(fx, p.position.y), Vector2(fx, p.position.y - 36.0), Palette.WARM, 2.5, true)
	draw_line(Vector2(p.position.x, p.position.y - 36.0), Vector2(p.end.x, p.position.y - 36.0), Palette.WARM, 2.5, true)

func _pipe(p: Rect2) -> void:
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 14.0), Palette.WARM)
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 14.0), Palette.INK, false, 2.0)
	for fx in [p.position.x + 14.0, p.end.x - 24.0]:
		draw_rect(Rect2(fx, p.position.y - 3.0, 10.0, 20.0), Palette.CHARCOAL)
	draw_line(Vector2(p.position.x + 18.0, p.position.y + 14.0), Vector2(p.position.x + 18.0, p.position.y + 36.0), Palette.CHARCOAL, 3.0)

func _ledge(p: Rect2) -> void:
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 9.0), Palette.CHARCOAL)
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 3.0), Palette.WARM)
	draw_line(Vector2(p.position.x + 8.0, p.position.y + 9.0), Vector2(p.position.x + 40.0, p.position.y + 40.0), Palette.INK, 3.0, true)
	draw_line(Vector2(p.end.x - 8.0, p.position.y + 9.0), Vector2(p.end.x - 40.0, p.position.y + 40.0), Palette.INK, 3.0, true)

func _gantry(p: Rect2) -> void:
	# passarela alta (H): treliça apoiada na torre + painel de cartaz
	draw_rect(Rect2(p.position.x - 8.0, p.position.y - 96.0, p.size.x + 16.0, 88.0), Palette.PAPER)
	draw_rect(Rect2(p.position.x - 8.0, p.position.y - 96.0, p.size.x + 16.0, 88.0), Palette.INK, false, 3.0)
	for i in range(0, 12):
		draw_line(Vector2(p.position.x - 8.0 + i * 16.0, p.position.y - 8.0), Vector2(p.position.x + 12.0 + i * 16.0, p.position.y - 96.0), Palette.WARM, 2.0)
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 9.0), Palette.CHARCOAL)
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 3.0), Palette.WARM)
	var base := 520.0
	for sx in [p.position.x + 6.0, p.end.x - 6.0]:
		draw_line(Vector2(sx, p.position.y + 9.0), Vector2(sx, base), Palette.INK, 4.0)
	draw_line(Vector2(p.position.x + 6.0, p.position.y + 9.0), Vector2(p.end.x - 6.0, base), Palette.INK, 2.0, true)
	draw_line(Vector2(p.end.x - 6.0, p.position.y + 9.0), Vector2(p.position.x + 6.0, base), Palette.INK, 2.0, true)

func _water_tower() -> void:
	var cx := 1700.0
	var base := 520.0
	for lx in [cx - 46.0, cx + 46.0]:
		draw_line(Vector2(lx, base), Vector2(lx, base - 108.0), Palette.INK, 6.0)
	draw_line(Vector2(cx - 46.0, base), Vector2(cx + 46.0, base - 108.0), Palette.CHARCOAL, 3.0, true)
	draw_line(Vector2(cx + 46.0, base), Vector2(cx - 46.0, base - 108.0), Palette.CHARCOAL, 3.0, true)
	var tank := Rect2(cx - 62.0, base - 218.0, 124.0, 112.0)
	draw_rect(tank, Palette.MID)
	for i in 4:
		draw_rect(Rect2(tank.position.x, tank.position.y + 12.0 + i * 26.0, tank.size.x, 4.0), Palette.CHARCOAL)
	draw_rect(tank, Palette.INK, false, 3.0)
	var dome := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		dome.append(Vector2(cx, tank.position.y) + Vector2(cos(a) * 62.0, sin(a) * 44.0))
	draw_colored_polygon(dome, Palette.WARM)
	dome.append(dome[0])
	draw_polyline(dome, Palette.INK, 3.0, true)
	draw_line(Vector2(cx, tank.position.y - 44.0), Vector2(cx, tank.position.y - 62.0), Palette.INK, 3.0, true)
	draw_line(Vector2(cx - 62.0, tank.end.y), Vector2(cx - 62.0, base), Palette.INK, 3.0)
