extends Node2D
## Desenho procedural do gato (vetorial, só paleta oficial). A origem fica nos pés.
## Corpo, cabeça, orelhas, quatro patas e cauda de molas respondem ao estado e ao peso.

const TAIL_SEGS := 5

var player: Player
var t := 0.0
var squash := 0.0
var squash_vel := 0.0
var tail_ang: Array[float] = []
var tail_vel: Array[float] = []
var blink_timer := 2.4
var blink := 0.0
var ear_timer := 3.2
var ear_twitch := 0.0
var eat_timer := 0.0
var dust: Array[Dictionary] = []
var head_tilt := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20261118
	player = get_parent() as Player
	for i in TAIL_SEGS:
		tail_ang.append(PI + 0.42 + i * 0.30)
		tail_vel.append(0.0)
	player.landed.connect(_on_landed)
	player.jumped.connect(func() -> void: squash_vel -= 6.0)
	player.ate.connect(func(_k: String) -> void: eat_timer = 0.55)

func _on_landed(impact: float) -> void:
	squash_vel += impact * 11.0 * (0.6 + 0.9 * player.weight)
	if impact > 0.3:
		for s in [-1, 1]:
			dust.append({"pos": Vector2(s * 16.0, -3.0), "vel": Vector2(s * (40.0 + impact * 90.0), -14.0), "age": 0.0, "life": 0.45, "r": 3.0 + impact * 4.0})

func _process(delta: float) -> void:
	t += delta
	scale.x = float(player.facing)
	# mola de achatamento
	squash_vel += (-170.0 * squash - 16.0 * squash_vel) * delta
	squash += squash_vel * delta
	# piscar e orelhas
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink = 0.12
		blink_timer = _rng.randf_range(2.6, 5.2)
	blink = maxf(blink - delta, 0.0)
	ear_timer -= delta
	if ear_timer <= 0.0:
		ear_twitch = 1.0
		ear_timer = _rng.randf_range(3.0, 6.5)
	ear_twitch = maxf(ear_twitch - delta * 2.4, 0.0)
	eat_timer = maxf(eat_timer - delta, 0.0)
	_update_tail(delta)
	for d in dust:
		d["age"] += delta
		d["pos"] += d["vel"] * delta
		d["vel"] *= 0.92
	dust = dust.filter(func(d: Dictionary) -> bool: return d["age"] < d["life"])
	queue_redraw()

func _update_tail(delta: float) -> void:
	var w := player.weight
	var run_f := clampf(absf(player.velocity.x) / player.params.run_speed, 0.0, 1.0)
	var air_up := 0.0
	if player.pose == Player.Pose.JUMP:
		air_up = -0.55
	elif player.pose == Player.Pose.FALL:
		air_up = 0.5
	for i in TAIL_SEGS:
		var rest := PI + 0.42 + i * 0.30
		var flat := PI + 0.10 + i * 0.05
		var target := lerpf(rest, flat, run_f * 0.8)
		target += sin(t * (1.5 + i * 0.12) - i * 0.6) * (0.04 + i * 0.03) * (1.0 - run_f * 0.5)
		target += air_up * (float(i) / TAIL_SEGS)
		var k := 120.0 - i * 6.0
		var c := 11.0 + w * 3.0
		tail_vel[i] += ((target - tail_ang[i]) * k - tail_vel[i] * c) * delta
		tail_ang[i] += tail_vel[i] * delta

# ---------- utilidades de desenho ----------
func _ell(c: Vector2, rx: float, ry: float, n := 30) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _crescent(c: Vector2, rx: float, ry: float, a0: float, a1: float, inner: float, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	for i in n + 1:
		var a := lerpf(a1, a0, float(i) / n)
		var wob := 1.0 + 0.10 * sin(a * 3.0)
		pts.append(c + Vector2(cos(a) * rx * inner * wob, sin(a) * ry * inner * wob))
	return pts

func _shape(pts: PackedVector2Array, fill: Color, lw := 2.2) -> void:
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Palette.INK, lw, true)

func _leg(hip: Vector2, foot: Vector2, width: float, fill: Color) -> void:
	draw_line(hip, foot, Palette.INK, width + 3.6, true)
	draw_circle(foot, width * 0.5 + 1.8, Palette.INK)
	draw_line(hip, foot, fill, width, true)
	draw_circle(foot, width * 0.5, fill)

func _draw() -> void:
	var w := player.weight
	var vx := absf(player.velocity.x)
	var run_f := clampf(vx / player.params.run_speed, 0.0, 1.0)
	var pose := player.pose
	var air := pose == Player.Pose.JUMP or pose == Player.Pose.FALL

	var bw := lerpf(26.0, 37.0, w)
	var bh := lerpf(16.0, 27.0, w)
	var leg_h := lerpf(6.5, 2.5, w)
	var head_r := lerpf(12.5, 16.5, w)
	var leg_w := lerpf(9.0, 13.0, w)

	# achatamento / alongamento + inclinação
	var stretch := clampf(absf(player.velocity.y) / 1300.0, 0.0, 0.12) if air else 0.0
	var sy := 1.0 - 0.30 * squash + stretch
	var sx := 1.0 / pow(maxf(sy, 0.6), 0.6)
	var lean := 0.07 * run_f
	if pose == Player.Pose.SKID:
		lean = -0.13
	elif pose == Player.Pose.JUMP:
		lean = -0.10
	elif pose == Player.Pose.FALL:
		lean = 0.08
	draw_set_transform(Vector2.ZERO, lean, Vector2(sx, sy))

	var bob := 0.0
	var breath := 0.0
	match pose:
		Player.Pose.RUN: bob = absf(sin(player.run_phase)) * -2.6 * (0.6 + w)
		Player.Pose.WALK: bob = absf(sin(player.run_phase)) * -1.4
		Player.Pose.IDLE: breath = sin(t * lerpf(2.6, 1.8, w)) * (0.012 + 0.02 * w)
	var cy := -(leg_h + bh) + bob
	var bc := Vector2(0.0, cy)

	# --- sombra de contato
	if not air:
		var sh := _ell(Vector2(0, 1.2), bw * 0.8, 2.0, 20)
		draw_colored_polygon(sh, Palette.CHARCOAL)

	# --- cauda (atrás do corpo)
	var tp := Vector2(-bw * 0.90, cy - bh * 0.05)
	var seg := lerpf(7.5, 9.5, w)
	for i in TAIL_SEGS:
		var np := tp + Vector2.from_angle(tail_ang[i]) * seg
		var tw := lerpf(11.0, 6.5, float(i) / TAIL_SEGS) * lerpf(0.9, 1.15, w)
		draw_line(tp, np, Palette.INK, tw, true)
		draw_circle(np, tw * 0.5, Palette.INK)
		tp = np

	# --- patas (calcula posições)
	var hy := cy + bh * 0.74
	var hips := [Vector2(bw * 0.52, hy), Vector2(bw * 0.52 - 7, hy + 1.5), Vector2(-bw * 0.52, hy), Vector2(-bw * 0.52 + 7, hy + 1.5)]
	# ordem: 0 frente-perto, 1 frente-longe, 2 trás-perto, 3 trás-longe
	var offs := [0.0, PI, PI, 0.0]
	var feet: Array[Vector2] = []
	var amp := lerpf(6.0, 11.0, run_f) * lerpf(1.0, 0.75, w)
	var lift := lerpf(3.0, 7.0, run_f)
	for i in 4:
		var h: Vector2 = hips[i]
		var f := Vector2(h.x, 0.0)
		if air:
			var up := -4.0 - (leg_h + bh * 0.55) * 0.45
			if pose == Player.Pose.JUMP:
				f = Vector2(h.x + (13.0 if i < 2 else -14.0), up)
			else:
				f = Vector2(h.x + (9.0 if i < 2 else -8.0), up * 0.55)
		elif pose == Player.Pose.WALK or pose == Player.Pose.RUN:
			var ph: float = player.run_phase + float(offs[i])
			f = Vector2(h.x + sin(ph) * amp, -maxf(0.0, cos(ph)) * lift)
		elif pose == Player.Pose.SKID:
			f = Vector2(h.x + (12.0 if i < 2 else 4.0), 0.0)
		feet.append(f)
	_leg(hips[3], feet[3], leg_w * 0.9, Palette.WARM)
	_leg(hips[1], feet[1], leg_w * 0.9, Palette.WARM)

	# --- corpo
	var ry := bh * (1.0 + breath)
	_shape(_ell(bc, bw, ry), Palette.IVORY)
	draw_colored_polygon(_crescent(bc, bw * 0.985, ry * 0.985, -2.75, -1.05, 0.52), Palette.INK)
	var out := _ell(bc, bw, ry)
	out.append(out[0])
	draw_polyline(out, Palette.INK, 2.2, true)

	_leg(hips[2], feet[2], leg_w, Palette.IVORY)
	_leg(hips[0], feet[0], leg_w, Palette.IVORY)

	# --- cabeça
	var look := 0.0
	if pose == Player.Pose.JUMP:
		look = -0.18
	elif pose == Player.Pose.FALL:
		look = 0.14
	look += sin(t * 0.7) * 0.03
	if eat_timer > 0.0:
		look += 0.28 + sin(t * 26.0) * 0.05
	var hc := Vector2(bw * 0.74 + (2.0 if pose == Player.Pose.RUN else 0.0), cy - bh * 0.18 + lerpf(0.0, 4.0, w))
	var hr_x := head_r * lerpf(1.14, 1.26, w)
	var hr_y := head_r * 1.0
	draw_set_transform(Vector2.ZERO, lean, Vector2(sx, sy))
	var run_back := 3.5 * run_f
	var tw := sin(ear_twitch * 38.0) * 2.0 * ear_twitch
	# orelha de trás (longe)
	var far_ear := PackedVector2Array([hc + Vector2(hr_x * 0.10, -hr_y * 0.80), hc + Vector2(hr_x * 0.78, -hr_y * 0.50), hc + Vector2(hr_x * 0.58 - run_back, -hr_y * 1.62 + run_back * 0.5)])
	_shape(far_ear, Palette.IVORY)
	# orelha da frente (perto) — preta
	var near_ear := PackedVector2Array([hc + Vector2(-hr_x * 0.66, -hr_y * 0.40), hc + Vector2(-hr_x * 0.02, -hr_y * 0.95), hc + Vector2(-hr_x * 0.44 - run_back + tw, -hr_y * 1.66 + run_back * 0.5)])
	_shape(near_ear, Palette.INK)
	var head := _ell(hc, hr_x, hr_y)
	_shape(head, Palette.IVORY)
	draw_colored_polygon(_crescent(hc, hr_x * 0.985, hr_y * 0.985, -3.2, -0.95, 0.48), Palette.INK)
	var hout := head.duplicate()
	hout.append(head[0])
	draw_polyline(hout, Palette.INK, 2.2, true)
	# rosto
	var ex := hc.x + hr_x * 0.34
	var ey := hc.y - hr_y * 0.04 + look * 6.0
	if blink > 0.0:
		draw_line(Vector2(ex - 3.0, ey), Vector2(ex + 2.5, ey), Palette.INK, 1.8, true)
		draw_line(Vector2(ex + 7.5, ey), Vector2(ex + 11.5, ey), Palette.INK, 1.6, true)
	else:
		draw_circle(Vector2(ex, ey), 3.1, Palette.INK)
		draw_circle(Vector2(ex + 9.5, ey), 2.8, Palette.INK)
		draw_circle(Vector2(ex - 0.6, ey - 0.9), 0.8, Palette.IVORY)
		draw_circle(Vector2(ex + 8.4, ey - 0.8), 0.7, Palette.IVORY)
	draw_colored_polygon(_ell(Vector2(hc.x + hr_x * 0.88, ey + hr_y * 0.30), 2.6, 1.8, 10), Palette.CHARCOAL)
	var mouth_open := 1.5 if (eat_timer > 0.0 and sin(t * 26.0) > 0.0) else 0.0
	draw_polyline(PackedVector2Array([Vector2(hc.x + hr_x * 0.80, ey + hr_y * 0.46), Vector2(hc.x + hr_x * 0.62, ey + hr_y * 0.58 + mouth_open), Vector2(hc.x + hr_x * 0.40, ey + hr_y * 0.50)]), Palette.INK, 1.5, true)

	# --- poeira da aterrissagem
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for d in dust:
		var k: float = d["age"] / d["life"]
		var r: float = d["r"] * (1.0 + k * 1.6)
		draw_arc(d["pos"], r, 0.0, TAU, 16, Palette.MID, maxf(0.6, 2.2 * (1.0 - k)), true)
