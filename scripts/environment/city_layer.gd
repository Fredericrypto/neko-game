extends Node2D
## Skyline em camadas (0 = distante, 1 = intermediária). Geometria Bauhaus, só valores tonais.

@export var kind := 0
var font: Font

func _ready() -> void:
	font = load("res://assets/fonts/ZenKakuGothicNew-Medium.ttf")

func _windows(r: Rect2, body: Color, rng: RandomNumberGenerator, cw: float, ch: float, lit_chance: float) -> void:
	var dark: Color = Palette.WARM
	if body == Palette.WARM:
		dark = Palette.MID if kind != 0 else Palette.PAPER
	elif body == Palette.MID:
		dark = Palette.CHARCOAL
	var cols := int(r.size.x / cw)
	var rows := mini(int((r.size.y - 14.0) / ch), 12)
	for cy in rows:
		for cx in cols:
			var roll := rng.randf()
			var wr := Rect2(r.position.x + 6.0 + cx * cw, r.position.y + 12.0 + cy * ch, cw - 7.0, ch - 8.0)
			if roll < lit_chance:
				draw_rect(wr, Palette.IVORY)
			elif roll < 0.82:
				draw_rect(wr, dark)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711 + kind * 977
	var base_y := 1100.0
	var x := -1800.0
	var far := kind == 0
	while x < 5600.0:
		var bw := rng.randf_range(60.0, 130.0) * (1.0 if far else 1.35)
		var bh := rng.randf_range(600.0, 790.0) if far else rng.randf_range(520.0, 740.0)
		var pick := rng.randf()
		var body: Color
		if far:
			body = Palette.PAPER if pick < 0.6 else Palette.WARM
		else:
			body = Palette.WARM if pick < 0.45 else (Palette.MID if pick < 0.8 else Palette.PAPER)
		var r := Rect2(x, base_y - bh, bw, bh)
		draw_rect(r, body)
		draw_rect(Rect2(r.position.x, r.position.y, bw, 4.0), Palette.WARM if body == Palette.PAPER else (Palette.MID if body == Palette.WARM else Palette.CHARCOAL))
		_windows(r, body, rng, 20.0 if far else 26.0, 24.0 if far else 30.0, 0.0 if far else 0.04)
		if rng.randf() < 0.35:
			var ax := r.position.x + bw * rng.randf_range(0.2, 0.8)
			draw_line(Vector2(ax, r.position.y), Vector2(ax, r.position.y - rng.randf_range(24.0, 60.0)), Palette.MID if far else Palette.CHARCOAL, 2.0, true)
		x += bw + rng.randf_range(0.0, 10.0)
	if not far:
		_landmarks()
	# névoa de impressão: listras de Ivory que engrossam para baixo (sem tons intermediários)
	var fog_h := 330.0 if far else 190.0
	var y := base_y - fog_h
	while y < base_y:
		var k := (y - (base_y - fog_h)) / fog_h
		var th := (5.0 if far else 3.2) * pow(k, 1.2) + 0.2
		draw_rect(Rect2(-1800.0, y, 7400.0, th), Palette.IVORY)
		y += 5.0
	draw_rect(Rect2(-1800.0, base_y - 2.0, 7400.0, 6.0), Palette.IVORY)

func _landmarks() -> void:
	# caixa d'água com cúpula (referência do conceito)
	var wx := 760.0
	draw_rect(Rect2(wx, 560.0, 150.0, 540.0), Palette.MID)
	for i in 6:
		draw_rect(Rect2(wx + 12.0, 590.0 + i * 52.0, 126.0, 6.0), Palette.WARM)
	draw_rect(Rect2(wx + 40.0, 520.0, 70.0, 40.0), Palette.WARM)
	draw_colored_polygon(_dome(Vector2(wx + 75.0, 520.0), 38.0), Palette.MID)
	draw_line(Vector2(wx + 75.0, 484.0), Vector2(wx + 75.0, 462.0), Palette.CHARCOAL, 3.0, true)
	# letreiro vertical むちねこ
	var sx := 1180.0
	draw_rect(Rect2(sx, 470.0, 190.0, 630.0), Palette.WARM)
	_windows_static(Rect2(sx, 470.0, 190.0, 630.0))
	var sign_r := Rect2(sx + 62.0, 520.0, 52.0, 230.0)
	draw_rect(sign_r, Palette.PAPER)
	draw_rect(sign_r, Palette.INK, false, 3.0)
	var chars := ["む", "ち", "ね", "こ"]
	for i in 4:
		draw_char(font, Vector2(sign_r.position.x + 9.0, sign_r.position.y + 44.0 + i * 54.0), chars[i], 40, Palette.INK)
	# torre com janelas em grade
	var tx := 1500.0
	draw_rect(Rect2(tx, 330.0, 140.0, 770.0), Palette.CHARCOAL)
	for ry in 9:
		for rx in 4:
			draw_rect(Rect2(tx + 12.0 + rx * 32.0, 350.0 + ry * 44.0, 22.0, 30.0), Palette.MID if (rx + ry) % 5 != 0 else Palette.IVORY)
	draw_rect(Rect2(tx + 20.0, 318.0, 100.0, 12.0), Palette.INK)

func _windows_static(r: Rect2) -> void:
	for ry in int((r.size.y - 30.0) / 54.0):
		for rx in 5:
			var wx := r.position.x + 12.0 + rx * 34.0
			var wy := r.position.y + 24.0 + ry * 54.0
			if wx > r.position.x + 56.0 and wx < r.position.x + 120.0 and wy < 780.0:
				continue
			draw_rect(Rect2(wx, wy, 22.0, 34.0), Palette.MID)

func _dome(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.9))
	return pts
