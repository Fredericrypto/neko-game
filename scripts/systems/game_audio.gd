extends Node
## Áudio básico (sons suaves gerados em tools/generate_audio.py; origem própria, sem licença externa).
## Espacialização binaural completa fica para uma etapa posterior (AUDIO_BIBLE).

var player: Player
var sfx := {}
var steps: Array[AudioStream] = []
var amb: AudioStreamPlayer
var wind: AudioStreamPlayer
var p_step: AudioStreamPlayer
var p_jump: AudioStreamPlayer
var p_land: AudioStreamPlayer
var p_eat: AudioStreamPlayer
var p_door: AudioStreamPlayer2D
var t := 0.0
var _step_i := 0

func _loop(path: String) -> AudioStream:
	var s := load(path) as AudioStreamWAV
	if s:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	return s

func _mk(bus := "Master") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p

func setup(pl: Player, door: Node2D) -> void:
	player = pl
	for i in 3:
		steps.append(load("res://assets/audio/step_%d.wav" % (i + 1)))
	p_step = _mk()
	p_jump = _mk()
	p_land = _mk()
	p_eat = _mk()
	p_jump.stream = load("res://assets/audio/jump.wav")
	p_land.stream = load("res://assets/audio/land.wav")
	p_eat.stream = load("res://assets/audio/eat.wav")
	amb = _mk()
	amb.stream = _loop("res://assets/audio/ambience_city.wav")
	amb.volume_db = -17.0
	amb.play()
	wind = _mk()
	wind.stream = _loop("res://assets/audio/wind.wav")
	wind.volume_db = -24.0
	wind.play()
	p_door = AudioStreamPlayer2D.new()
	p_door.stream = load("res://assets/audio/door.wav")
	p_door.volume_db = -8.0
	p_door.max_distance = 900.0
	p_door.global_position = door.global_position
	add_child(p_door)
	player.footstep.connect(_on_step)
	player.jumped.connect(_on_jump)
	player.landed.connect(_on_land)
	player.ate.connect(_on_eat)
	if door.has_signal("toggled"):
		door.toggled.connect(func(_o: bool) -> void: p_door.play())

func _process(delta: float) -> void:
	t += delta
	if wind:
		wind.volume_db = -26.0 + 7.0 * maxf(0.0, sin(t * 0.37) * sin(t * 0.91 + 1.3))

func _on_step() -> void:
	_step_i = (_step_i + 1) % steps.size()
	p_step.stream = steps[_step_i]
	var sp := clampf(absf(player.velocity.x) / player.params.run_speed, 0.3, 1.0)
	p_step.pitch_scale = lerpf(1.18, 0.78, player.weight) + randf_range(-0.04, 0.04)
	p_step.volume_db = lerpf(-24.0, -13.0, sp) + lerpf(-2.0, 2.5, player.weight)
	p_step.play()

func _on_jump() -> void:
	p_jump.pitch_scale = lerpf(1.12, 0.86, player.weight)
	p_jump.volume_db = -15.0
	p_jump.play()

func _on_land(impact: float) -> void:
	p_land.pitch_scale = lerpf(1.1, 0.72, player.weight)
	p_land.volume_db = lerpf(-24.0, -8.0, impact) + lerpf(-2.0, 3.0, player.weight)
	p_land.play()

func _on_eat(kind: String) -> void:
	p_eat.pitch_scale = 0.85 if kind == "can" else 1.0 + randf_range(-0.05, 0.08)
	p_eat.volume_db = -12.0
	p_eat.play()
