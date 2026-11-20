extends Node2D
## Céu de papel: degradê tonal Ivory -> Paper, ancorado à câmera (não rola).

func _process(_d: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		global_position = cam.get_screen_center_position()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-700.0, -380.0, 1400.0, 760.0), Palette.IVORY)
	var y := -380.0
	while y < 380.0:
		var k := (y + 380.0) / 760.0
		var th := 3.0 * pow(k, 1.5)
		if th > 0.4:
			draw_rect(Rect2(-700.0, y, 1400.0, th), Palette.PAPER)
		y += 6.0
