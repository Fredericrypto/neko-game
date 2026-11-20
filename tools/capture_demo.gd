extends SceneTree
## Captura de cenas reais da execução (renderização por software em Xvfb).
## Uso: godot --path . --rendering-driver opengl3 -s tools/capture_demo.gd -- <pasta_de_saida>

var main: Node
var player: Player
var cam: Camera2D
var out := "res://screenshots"

func act(name: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = name
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("CAPTURA ", name)

func release_all() -> void:
	for a in ["move_left", "move_right", "jump", "run", "move_down"]:
		act(a, false)

func put(pos: Vector2, w: float, vx := 0.0, settle := 40) -> void:
	release_all()
	player.velocity = Vector2(vx, 0.0)
	player.global_position = pos
	player.set_weight(w)
	cam.snap()
	await frames(settle)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	player = main.get_node("Player")
	cam = main.get_node("Camera")
	player.params.burn_run = 0.0
	player.params.burn_walk = 0.0

	await put(Vector2(300.0, 640.0), 0.42, 0.0, 90)
	await shot("01_idle")
	await put(Vector2(100.0, 640.0), 0.42, 0.0, 10)
	act("move_right", true)
	await frames(34)
	await shot("02_walk")
	act("run", true)
	await frames(46)
	await shot("03_run")
	release_all()
	# salto de corrida (apex)
	await put(Vector2(120.0, 640.0), 0.42, 0.0, 10)
	act("move_right", true)
	act("run", true)
	await frames(30)
	act("jump", true)
	await frames(24)
	await shot("04_jump")
	act("jump", false)
	await frames(30)
	await shot("05_fall")
	release_all()
	# aterrissagem do gato pesado (achatamento)
	await put(Vector2(300.0, 640.0), 0.9, 0.0, 30)
	act("jump", true)
	await frames(30)
	act("jump", false)
	var seen := false
	for i in 90:
		await physics_frame
		if player.pose == Player.Pose.LAND:
			seen = true
			await frames(2)
			break
	await shot("06_land_heavy")
	# os três pesos, parados lado a lado em capturas separadas
	for pair in [["07_weight_light", 0.08], ["08_weight_normal", 0.45], ["09_weight_heavy", 0.92]]:
		await put(Vector2(400.0, 640.0), pair[1], 0.0, 80)
		await shot(pair[0])
	# fogo de escada (exploração por baixo) e beco
	await put(Vector2(1090.0, 880.0), 0.42, 0.0, 60)
	await shot("10_fire_escape")
	# topo da torre, caixa d'água e antenas
	await put(Vector2(1830.0, 520.0), 0.42, 0.0, 60)
	await shot("11_tower_water")
	# passarela opcional H com a lata
	await put(Vector2(1900.0, 380.0), 0.10, 0.0, 60)
	await shot("12_optional_ledge")
	# porta aberta com janela acesa
	await put(Vector2(2330.0, 760.0), 0.42, 0.0, 40)
	act("interact", true)
	await frames(2)
	act("interact", false)
	await frames(50)
	await shot("13_door_open")
	# C, ventilador, fim do mundo
	await put(Vector2(2600.0, 760.0), 0.42, 0.0, 60)
	await shot("14_roof_c")
	# visão ampla: o jogo real com a câmera afastada
	cam.target = null
	cam.zoom = Vector2(0.4, 0.4)
	cam.limit_left = -10000
	cam.limit_right = 10000
	cam.limit_top = -10000
	cam.limit_bottom = 10000
	cam.global_position = Vector2(1500.0, 640.0)
	await frames(10)
	await shot("15_wide_view")
	# pausa
	cam.zoom = Vector2(1.15, 1.15)
	cam.target = player
	await put(Vector2(300.0, 640.0), 0.42, 0.0, 30)
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await process_frame
	await process_frame
	await shot("16_pause")
	quit()
