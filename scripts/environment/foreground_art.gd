extends Node2D
## Primeiro plano discreto: dois cabos soltos à frente da cena, para dar profundidade.

var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	_cable(Vector2(1400.0, 250.0), Vector2(2260.0, 300.0), 70.0, 0.0)
	_cable(Vector2(1420.0, 262.0), Vector2(2250.0, 318.0), 82.0, 0.7)

func _cable(a: Vector2, b: Vector2, sag: float, ph: float) -> void:
	var pts := PackedVector2Array()
	var sway := sin(t * 0.9 + ph) * 3.0
	for s in 33:
		var k := float(s) / 32.0
		pts.append(a.lerp(b, k) + Vector2(0.0, sin(k * PI) * (sag + sway)))
	draw_polyline(pts, Palette.INK, 1.8, true)
