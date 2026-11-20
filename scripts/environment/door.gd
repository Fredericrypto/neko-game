class_name Door
extends Area2D
## Porta da casa de escada (E para abrir/fechar). Demonstra interação + janela que acende.

var open := 0.0
var want_open := false
var near := false
var t := 0.0
var font: Font
var player: Player

signal toggled(is_open: bool)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(110.0, 90.0)
	cs.shape = sh
	cs.position = Vector2(0.0, -40.0)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(func(b: Node) -> void:
		if b is Player:
			near = false)
	font = load("res://assets/fonts/ZenKakuGothicNew-Medium.ttf")
	z_index = -3

func _on_enter(b: Node) -> void:
	if b is Player:
		player = b as Player
		near = true
		if not player.interact_pressed.is_connected(_on_interact):
			player.interact_pressed.connect(_on_interact)

func _on_interact() -> void:
	if near:
		want_open = not want_open
		toggled.emit(want_open)

func _process(delta: float) -> void:
	t += delta
	open = move_toward(open, 1.0 if want_open else 0.0, delta * 2.6)
	queue_redraw()

func _draw() -> void:
	# vão da porta (local: base em y=0)
	var frame := Rect2(-24.0, -72.0, 48.0, 72.0)
	draw_rect(frame.grow(3.0), Palette.INK)
	if open > 0.01:
		draw_rect(frame, Palette.IVORY)
		for i in 5:
			draw_rect(Rect2(frame.position.x + 4.0 + i * 8.0, frame.position.y + 18.0 + i * 11.0, 40.0 - i * 8.0, 4.0), Palette.WARM)
	else:
		draw_rect(frame, Palette.CHARCOAL)
	# folha da porta: encolhe em perspectiva ao abrir
	var w := 48.0 * (1.0 - open * 0.78)
	draw_rect(Rect2(frame.position.x, frame.position.y, w, frame.size.y), Palette.CHARCOAL)
	draw_rect(Rect2(frame.position.x, frame.position.y, w, frame.size.y), Palette.INK, false, 2.0)
	if open < 0.5:
		draw_circle(Vector2(frame.position.x + w - 7.0, -34.0), 2.8, Palette.WARM)
		draw_rect(Rect2(frame.position.x + 6.0, frame.position.y + 8.0, w - 12.0, 16.0), Palette.INK)
	# janela ao lado: acende e a cortina balança
	var win := Rect2(38.0, -68.0, 28.0, 30.0)
	draw_rect(win.grow(3.0), Palette.INK)
	draw_rect(win, Palette.IVORY if open > 0.3 else Palette.CHARCOAL)
	if open > 0.3:
		var sw := sin(t * 2.3) * 3.0
		draw_colored_polygon(PackedVector2Array([win.position, win.position + Vector2(10.0 + sw, 0), win.position + Vector2(8.0 + sw * 1.4, 18.0), win.position + Vector2(0, 30.0)]), Palette.PAPER)
		draw_line(win.position + Vector2(10.0 + sw, 0), win.position + Vector2(8.0 + sw * 1.4, 18.0), Palette.MID, 1.2, true)
	draw_line(win.position + Vector2(14.0, 0), win.position + Vector2(14.0, 30.0), Palette.INK, 1.5)
	# aviso "E"
	if near:
		var pill := Rect2(-14.0, -104.0 + sin(t * 3.0) * 2.0, 28.0, 24.0)
		draw_rect(pill, Palette.IVORY)
		draw_rect(pill, Palette.INK, false, 2.0)
		draw_char(font, pill.position + Vector2(8.0, 18.0), "E", 16, Palette.INK)
