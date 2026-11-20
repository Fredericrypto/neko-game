extends Camera2D
## Câmera de acompanhamento: antecipação, zona morta vertical e suavização exponencial.
## Parâmetros provisórios; o enquadramento definitivo continua pendente na documentação.

@export var target: Player
@export var look_ahead := 150.0
@export var follow_x := 5.0
@export var follow_y := 3.2
@export var dead_zone_y := 90.0
@export var base_offset_y := -70.0

var _focus_y := 0.0
var _look := 0.0
var _initialized := false

func snap() -> void:
	if target == null:
		return
	_focus_y = target.global_position.y
	_look = 0.0
	global_position = Vector2(target.global_position.x, _focus_y + base_offset_y)
	reset_smoothing()
	_initialized = true

func _physics_process(delta: float) -> void:
	if target == null:
		return
	if not _initialized:
		snap()
	var vx := target.velocity.x
	var want_look := clampf(vx / target.params.run_speed, -1.0, 1.0) * look_ahead
	_look = lerpf(_look, want_look, 1.0 - exp(-2.6 * delta))
	# vertical: só acompanha ao sair da zona morta ou ao pousar
	var py := target.global_position.y
	if target.is_on_floor():
		_focus_y = lerpf(_focus_y, py, 1.0 - exp(-follow_y * delta))
	else:
		if py < _focus_y - dead_zone_y:
			_focus_y = lerpf(_focus_y, py + dead_zone_y, 1.0 - exp(-follow_y * 1.6 * delta))
		elif py > _focus_y + dead_zone_y * 1.6:
			_focus_y = lerpf(_focus_y, py - dead_zone_y * 1.6, 1.0 - exp(-follow_y * 2.0 * delta))
	var goal := Vector2(target.global_position.x + _look, _focus_y + base_offset_y)
	global_position.x = lerpf(global_position.x, goal.x, 1.0 - exp(-follow_x * delta))
	global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-follow_y * delta))
