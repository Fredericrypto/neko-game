extends CanvasLayer
## Interface discreta no estilo do conceito: medidor de peso, contador de ração, pausa.
## Só paleta oficial. O indicador de peso e as teclas 1/2 são ferramentas de teste, não UI final.

const FONT_PATH := "res://assets/fonts/ZenKakuGothicNew-Medium.ttf"

var player: Player
var canvas: Control
var font: Font
var font_wide: FontVariation
var shown_weight := 0.42
var paused := false
var menu_index := 0
var hint_time := 0.0
var _items := ["RESUME", "RESTART", "QUIT"]
var _gauge_bg := StyleBoxFlat.new()
var _gauge_fill := StyleBoxFlat.new()

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = load(FONT_PATH)
	font_wide = FontVariation.new()
	font_wide.base_font = font
	font_wide.spacing_glyph = 3
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	add_child(canvas)
	for sb in [_gauge_bg, _gauge_fill]:
		sb.set_corner_radius_all(8)
	_gauge_bg.bg_color = Palette.PAPER
	_gauge_bg.border_color = Palette.INK
	_gauge_bg.set_border_width_all(2)
	_gauge_fill.bg_color = Palette.INK

func bind(p: Player) -> void:
	player = p
	shown_weight = p.weight

func _process(delta: float) -> void:
	if player == null:
		return
	hint_time += delta
	shown_weight = lerpf(shown_weight, player.weight, 1.0 - exp(-10.0 * delta))
	canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if not paused:
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		menu_index = (menu_index + 1) % _items.size()
	elif event.is_action_pressed("ui_up"):
		menu_index = (menu_index + _items.size() - 1) % _items.size()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		_activate(menu_index)
	get_viewport().set_input_as_handled()

func _set_paused(v: bool) -> void:
	paused = v
	get_tree().paused = v
	menu_index = 0

func _activate(i: int) -> void:
	match _items[i]:
		"RESUME":
			_set_paused(false)
		"RESTART":
			get_tree().paused = false
			get_tree().reload_current_scene()
		"QUIT":
			get_tree().quit()

func _txt(pos: Vector2, s: String, size: int, col: Color, wide := false, outline := true) -> void:
	var f: Font = font_wide if wide else font
	if outline and not paused:
		canvas.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 7, Palette.IVORY)
	canvas.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _txt_w(s: String, size: int, wide := false) -> float:
	return (font_wide if wide else font).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _draw_hud() -> void:
	if player == null:
		return
	# --- medidor de peso (conceito: WEIGHT / barra / 42%)
	_txt(Vector2(44.0, 50.0), "WEIGHT", 14, Palette.CHARCOAL, true)
	var bar := Rect2(44.0, 62.0, 200.0, 17.0)
	canvas.draw_style_box(_gauge_bg, bar)
	var fw := maxf(0.0, (bar.size.x - 6.0) * shown_weight)
	if fw > 2.0:
		canvas.draw_style_box(_gauge_fill, Rect2(bar.position.x + 3.0, bar.position.y + 3.0, maxf(fw, 11.0), bar.size.y - 6.0))
	_txt(Vector2(44.0, 106.0), "%d%%" % int(round(shown_weight * 100.0)), 15, Palette.CHARCOAL, true)
	_txt(Vector2(98.0, 106.0), player.params.band_name(shown_weight), 11, Palette.MID, true)
	# --- ração + pausa
	var cx := canvas.size.x - 168.0
	for i in 3:
		var c := Vector2(cx + 8.0 + (i % 2) * 11.0 + (6.0 if i == 2 else 0.0), 58.0 + (i / 2) * 9.0 - (3.0 if i == 2 else 0.0))
		canvas.draw_circle(c, 5.2, Palette.CHARCOAL)
		canvas.draw_arc(c, 5.2, 0.0, TAU, 14, Palette.INK, 1.5, true)
	_txt(Vector2(cx + 36.0, 66.0), "× %d" % player.kibble, 16, Palette.CHARCOAL, true)
	canvas.draw_rect(Rect2(canvas.size.x - 60.0, 50.0, 5.0, 20.0), Palette.INK)
	canvas.draw_rect(Rect2(canvas.size.x - 48.0, 50.0, 5.0, 20.0), Palette.INK)
	# --- dicas (somem aos poucos)
	var a := 1.0
	if hint_time < 16.0:
		var line1 := "A D  MOVE     SHIFT  RUN     SPACE  JUMP     E  INTERACT     S+SPACE  DROP     ESC  PAUSE"
		var line2 := "[1] [2]  WEIGHT TEST — temporary tool"
		var w := maxf(_txt_w(line1, 12, true), _txt_w(line2, 12, true)) + 40.0
		var pill := Rect2(40.0, canvas.size.y - 76.0, w, 50.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.IVORY
		sb.border_color = Palette.INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		canvas.draw_style_box(sb, pill)
		_txt(Vector2(60.0, pill.position.y + 21.0), line1, 12, Palette.INK, true)
		_txt(Vector2(60.0, pill.position.y + 40.0), line2, 12, Palette.MID, true)
	if paused:
		_draw_pause()

func _draw_pause() -> void:
	var sy := 0.0
	while sy < canvas.size.y:
		canvas.draw_rect(Rect2(0.0, sy, canvas.size.x, 2.0), Palette.IVORY)
		sy += 3.0
	var panel := Rect2(canvas.size.x * 0.5 - 190.0, canvas.size.y * 0.5 - 170.0, 380.0, 340.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.IVORY
	sb.border_color = Palette.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	canvas.draw_style_box(sb, panel)
	_txt(Vector2(panel.position.x + 36.0, panel.position.y + 62.0), "PAUSED", 26, Palette.INK, true)
	_txt(Vector2(panel.position.x + 38.0, panel.position.y + 88.0), "一時停止", 14, Palette.MID, true)
	canvas.draw_line(Vector2(panel.position.x + 36.0, panel.position.y + 104.0), Vector2(panel.position.x + 96.0, panel.position.y + 104.0), Palette.INK, 2.0)
	for i in _items.size():
		var y := panel.position.y + 150.0 + i * 52.0
		var sel := i == menu_index
		if sel:
			var pill := StyleBoxFlat.new()
			pill.bg_color = Palette.INK
			pill.set_corner_radius_all(14)
			canvas.draw_style_box(pill, Rect2(panel.position.x + 28.0, y - 26.0, panel.size.x - 56.0, 40.0))
		_txt(Vector2(panel.position.x + 52.0, y), _items[i], 18, Palette.IVORY if sel else Palette.CHARCOAL, true)
	_txt(Vector2(panel.position.x + 36.0, panel.end.y - 22.0), "W S  SELECT     SPACE  CONFIRM     ESC  RESUME", 11, Palette.MID, true)
