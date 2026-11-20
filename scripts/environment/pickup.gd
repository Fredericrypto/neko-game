extends Area2D
## Comida colecionável: "kibble" (carinho) ou "can" (lata, recompensa maior). Ver CORE_GAMEPLAY.

@export var kind := "kibble"
var t := 0.0
var taken := false
var pop := 0.0
var _phase := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 20.0 if kind == "kibble" else 28.0
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)
	_phase = fmod(position.x * 0.013 + position.y * 0.007, TAU)
	z_index = 5

func _on_body(b: Node) -> void:
	if taken or not (b is Player):
		return
	taken = true
	(b as Player).eat(kind)

func _process(delta: float) -> void:
	t += delta
	if taken:
		pop += delta
		if pop > 0.35:
			queue_free()
	queue_redraw()

func _draw() -> void:
	var bob := sin(t * 2.2 + _phase) * 3.0
	if taken:
		var k := pop / 0.35
		draw_arc(Vector2(0, bob), 8.0 + k * 22.0, 0.0, TAU, 24, Palette.INK, maxf(0.6, 2.4 * (1.0 - k)), true)
		return
	if kind == "kibble":
		var c := Vector2(0, bob)
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(c + Vector2(cos(a) * 9.5, sin(a) * 8.0) * (1.0 + 0.08 * sin(a * 3.0 + 1.0)))
		draw_colored_polygon(pts, Palette.CHARCOAL)
		var ring := pts.duplicate()
		ring.append(pts[0])
		draw_polyline(ring, Palette.INK, 2.0, true)
		draw_circle(c + Vector2(-3.0, -3.0), 2.4, Palette.MID)
	else:
		var c := Vector2(0, bob)
		# raios pulsantes (como no conceito)
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		for i in 5:
			var a := -PI / 2.0 + (i - 2) * 0.5
			draw_line(c + Vector2.from_angle(a) * (26.0 + pulse * 3.0), c + Vector2.from_angle(a) * (34.0 + pulse * 5.0), Palette.INK, 2.0, true)
		draw_rect(Rect2(c.x - 19.0, c.y - 15.0, 38.0, 30.0), Palette.MID)
		draw_rect(Rect2(c.x - 19.0, c.y - 15.0, 38.0, 30.0), Palette.INK, false, 2.5)
		draw_rect(Rect2(c.x - 21.0, c.y - 17.0, 42.0, 5.0), Palette.WARM)
		draw_rect(Rect2(c.x - 21.0, c.y + 12.0, 42.0, 5.0), Palette.WARM)
		draw_circle(c, 9.5, Palette.IVORY)
		draw_circle(c, 9.5, Palette.INK, false, 1.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -5), c + Vector2(-8, -12), c + Vector2(-3, -7)]), Palette.INK)
		draw_colored_polygon(PackedVector2Array([c + Vector2(8, -5), c + Vector2(8, -12), c + Vector2(3, -7)]), Palette.INK)
		draw_circle(c + Vector2(-3.5, -1.0), 1.1, Palette.INK)
		draw_circle(c + Vector2(3.5, -1.0), 1.1, Palette.INK)
