class_name Player
extends CharacterBody2D
## Gato jogável: movimento terrestre, salto, peso contínuo (0..1) e estados para a animação.
## Todos os números vêm de MovementParams (provisórios).

signal jumped
signal landed(impact: float)
signal footstep
signal ate(kind: String)
signal weight_changed(value: float)
signal kibble_changed(count: int)
signal interact_pressed
signal respawned

enum Pose { IDLE, WALK, RUN, JUMP, FALL, LAND, SKID }

const LAYER_SOLID := 1
const LAYER_ONEWAY := 4
const KILL_Y := 1700.0

@export var params: MovementParams

var weight := 0.42
var kibble := 0
var facing := 1
var pose: Pose = Pose.IDLE
var run_phase := 0.0
var landing_timer := 0.0
var last_impact := 0.0
var skid_timer := 0.0
var input_enabled := true
var spawn_point := Vector2.ZERO

var _coyote := 0.0
var _buffer := 0.0
var _cut_allowed := false
var _was_on_floor := false
var _drop_timer := 0.0
var _step_index := 0
var _shape: RectangleShape2D

func _ready() -> void:
	if params == null:
		params = load("res://resources/movement_params.tres")
	weight = params.start_weight
	spawn_point = global_position
	collision_layer = 2
	collision_mask = LAYER_SOLID | LAYER_ONEWAY
	floor_snap_length = 10.0
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.06
	_shape = (get_node("Shape") as CollisionShape2D).shape.duplicate() as RectangleShape2D
	(get_node("Shape") as CollisionShape2D).shape = _shape
	_apply_body_size()

func set_weight(v: float) -> void:
	var nv := clampf(v, 0.0, 1.0)
	if is_equal_approx(nv, weight):
		return
	weight = nv
	_apply_body_size()
	weight_changed.emit(weight)

## Silhueta física: o corpo mais pesado ocupa mais espaço (colisão acompanha o visual).
func _apply_body_size() -> void:
	var w := lerpf(40.0, 54.0, weight)
	var h := lerpf(30.0, 42.0, weight)
	_shape.size = Vector2(w, h)
	(get_node("Shape") as CollisionShape2D).position = Vector2(0, -h * 0.5)

func eat(kind: String) -> void:
	if kind == "can":
		set_weight(weight + params.can_weight)
	else:
		kibble += 1
		kibble_changed.emit(kibble)
		set_weight(weight + params.kibble_weight)
	ate.emit(kind)

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	respawned.emit()

func _physics_process(delta: float) -> void:
	var p := params
	var dir := 0.0
	var running := false
	var jump_pressed := false
	var jump_released := false
	var jump_held := false
	var down := false
	if input_enabled:
		dir = Input.get_axis("move_left", "move_right")
		running = Input.is_action_pressed("run")
		jump_pressed = Input.is_action_just_pressed("jump")
		jump_released = Input.is_action_just_released("jump")
		jump_held = Input.is_action_pressed("jump")
		down = Input.is_action_pressed("move_down")
		if Input.is_action_pressed("weight_down"):
			set_weight(weight - p.weight_test_rate * delta)
		if Input.is_action_pressed("weight_up"):
			set_weight(weight + p.weight_test_rate * delta)
		if Input.is_action_just_pressed("interact"):
			interact_pressed.emit()

	var on_floor := is_on_floor()
	var spd := p.sample(weight, p.speed_mult_light, 1.0, p.speed_mult_heavy)
	var acc := p.sample(weight, p.accel_mult_light, 1.0, p.accel_mult_heavy)
	var jmp := p.sample(weight, p.jump_mult_light, 1.0, p.jump_mult_heavy)
	var gmul := p.sample(weight, p.gravity_mult_light, 1.0, p.gravity_mult_heavy)
	var max_speed := (p.run_speed if running else p.walk_speed) * spd

	# --- horizontal
	if absf(dir) > 0.1:
		var want := 1 if dir > 0.0 else -1
		if on_floor and absf(velocity.x) > p.skid_speed and signi(int(velocity.x)) != want:
			skid_timer = 0.18
		if on_floor or absf(velocity.x) < 40.0:
			facing = want
		elif signf(velocity.x) == float(want):
			facing = want
	var rate: float
	if on_floor:
		if absf(dir) < 0.1:
			rate = p.ground_decel * acc
		elif velocity.x != 0.0 and signf(velocity.x) != signf(dir):
			rate = p.turn_decel * acc
		else:
			rate = p.ground_accel * acc
	else:
		rate = (p.air_accel * acc) if absf(dir) > 0.1 else p.air_drag
	velocity.x = move_toward(velocity.x, dir * max_speed, rate * delta)
	skid_timer = maxf(skid_timer - delta, 0.0)

	# --- salto (coyote + buffer + altura variável)
	_coyote = p.coyote_time if on_floor else maxf(_coyote - delta, 0.0)
	_buffer = p.jump_buffer if jump_pressed else maxf(_buffer - delta, 0.0)
	if down and _buffer > 0.0 and on_floor and _standing_on_oneway():
		_drop_timer = 0.22
		_buffer = 0.0
	elif _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -p.jump_speed * jmp
		_buffer = 0.0
		_coyote = 0.0
		_cut_allowed = true
		on_floor = false
		jumped.emit()
	if jump_released and velocity.y < 0.0 and _cut_allowed:
		velocity.y *= p.jump_cut
		_cut_allowed = false

	# --- gravidade
	var g := p.gravity * gmul
	if velocity.y > 0.0:
		g *= p.fall_gravity_mult
	elif absf(velocity.y) < p.apex_window and jump_held:
		g *= p.apex_gravity_mult
	velocity.y = minf(velocity.y + g * delta, p.max_fall_speed)

	# --- plataformas de mão única: descer com S + pulo
	_drop_timer = maxf(_drop_timer - delta, 0.0)
	collision_mask = LAYER_SOLID if _drop_timer > 0.0 else (LAYER_SOLID | LAYER_ONEWAY)

	var vy_before := velocity.y
	move_and_slide()

	# --- aterrissagem
	on_floor = is_on_floor()
	if on_floor and not _was_on_floor:
		var impact := clampf(vy_before / p.max_fall_speed, 0.0, 1.0)
		last_impact = impact
		if impact > 0.10:
			landing_timer = p.land_recovery * (0.5 + weight)
			landed.emit(impact)
		_cut_allowed = false
	_was_on_floor = on_floor
	landing_timer = maxf(landing_timer - delta, 0.0)

	# --- metabolismo provisório: correr consome peso
	if on_floor and absf(velocity.x) > 20.0:
		var burn := p.burn_run if absf(velocity.x) > p.walk_speed * 1.2 else p.burn_walk
		weight = clampf(weight - burn * delta, 0.0, 1.0)
		weight_changed.emit(weight)

	# --- ciclo de passada + passos
	if on_floor:
		run_phase += absf(velocity.x) * delta * p.stride_rate
		var idx := int(floorf(run_phase / PI))
		if idx != _step_index and absf(velocity.x) > 30.0:
			footstep.emit()
		_step_index = idx

	_update_pose(on_floor)
	if global_position.y > KILL_Y:
		respawn()

func _standing_on_oneway() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is StaticBody2D and ((c.get_collider() as StaticBody2D).collision_layer & LAYER_ONEWAY) != 0:
			return true
	return false

func _update_pose(on_floor: bool) -> void:
	if not on_floor:
		pose = Pose.JUMP if velocity.y < 0.0 else Pose.FALL
	elif landing_timer > 0.0:
		pose = Pose.LAND
	elif skid_timer > 0.0:
		pose = Pose.SKID
	elif absf(velocity.x) < 12.0:
		pose = Pose.IDLE
	elif absf(velocity.x) > params.walk_speed * 1.25:
		pose = Pose.RUN
	else:
		pose = Pose.WALK
