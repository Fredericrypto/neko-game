extends SceneTree
## Testes automatizados (headless): godot --headless --path . -s tests/run_tests.gd
## Controla o jogador com eventos de entrada reais (InputEventAction) e mede o resultado.

var main: Node
var player: Player
var level: RooftopLevel
var passed := 0
var failed := 0
var report: Array[String] = []

func act(name: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = name
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		report.append("PASS  %s  %s" % [name, detail])
	else:
		failed += 1
		report.append("FAIL  %s  %s" % [name, detail])

func place(pos: Vector2, w: float, vx := 0.0) -> void:
	for a in ["move_left", "move_right", "jump", "run", "move_down"]:
		act(a, false)
	player.velocity = Vector2(vx, 0.0)
	player.global_position = pos
	player.set_weight(w)
	player.facing = 1 if vx >= 0.0 else -1
	await frames(4)

## Pulo de teste: parte de pos (pés), com velocidade horizontal inicial; segura o salto `hold` frames.
func try_jump(pos: Vector2, w: float, dir: int, run: bool, vx := 0.0, hold := 40, release_early := -1) -> Dictionary:
	await place(pos, w, vx)
	var apex := pos.y
	act("move_right" if dir > 0 else "move_left", dir != 0)
	act("run", run)
	act("jump", true)
	var airborne := false
	var landed_frames := 0
	for i in 240:
		await physics_frame
		if i == (release_early if release_early >= 0 else hold):
			act("jump", false)
		apex = minf(apex, player.global_position.y)
		if not player.is_on_floor():
			airborne = true
			landed_frames = 0
		elif airborne:
			landed_frames += 1
			if landed_frames > 6:
				break
	for a in ["move_left", "move_right", "jump", "run"]:
		act(a, false)
	return {"pos": player.global_position, "apex_h": pos.y - apex, "ok": player.is_on_floor()}

## Verdadeiro se ALGUM salto (varredura de tempo de segurar e velocidade de partida) pousa em `target`.
func reach(from: Vector2, w: float, dir: int, target: Rect2) -> bool:
	for hold in [10, 16, 22, 30, 40]:
		for vx in [0.0, 100.0, 220.0, 380.0]:
			var r := await try_jump(from, w, dir, vx > 300.0, vx * dir, hold)
			if r["ok"] and target.has_point(r["pos"] + Vector2(0.0, -1.0)):
				return true
	return false

func top(x0: float, y: float, w: float) -> Rect2:
	return Rect2(x0, y - 3.0, w, 6.0)

func _initialize() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames(2)
	player = main.get_node("Player")
	level = main.get_node("Level")
	await run_all()
	print("\n=========== RELATÓRIO DE TESTES ===========")
	for l in report:
		print(l)
	print("-------------------------------------------")
	print("Aprovados: %d   Falhos: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func run_all() -> void:
	# --- 1. inicialização e paleta
	check("boot: nós principais existem", player != null and level != null and main.get_node("HUD") != null and main.get_node("Camera") != null)
	var hexes := ["111111", "333333", "777777", "BEB8AD", "E6E1D7", "F6F4EE"]
	var got: Array[String] = []
	for c in Palette.all():
		got.append(c.to_html(false).to_upper())
	check("paleta: exatamente os seis tons oficiais", got == hexes, str(got))
	check("input map: ações definidas", InputMap.has_action("move_left") and InputMap.has_action("move_right") and InputMap.has_action("jump") and InputMap.has_action("run") and InputMap.has_action("interact") and InputMap.has_action("pause"))

	# --- 2. assentamento, ausência de jitter
	await place(RooftopLevel.SPAWN, 0.42)
	await frames(40)
	var ys: Array[float] = []
	for i in 60:
		await physics_frame
		ys.append(player.global_position.y)
	var spread: float = ys.max() - ys.min()
	check("chão: parado sem jitter (variação de y)", player.is_on_floor() and spread < 0.01 and absf(player.global_position.y - 640.0) < 1.0, "y=%.2f spread=%.4f" % [player.global_position.y, spread])

	# --- 3. caminhada, corrida, parada, ordem por peso
	var run_speeds := {}
	for w in [0.1, 0.42, 0.9]:
		await place(Vector2(-250.0, 640.0), w)
		act("move_right", true)
		act("run", true)
		await frames(70)
		run_speeds[w] = player.velocity.x
		act("move_right", false)
		act("run", false)
	check("corrida: velocidade máxima decresce com o peso", run_speeds[0.1] > run_speeds[0.42] and run_speeds[0.42] > run_speeds[0.9], str(run_speeds))
	var expect := player.params.run_speed * player.params.sample(0.42, player.params.speed_mult_light, 1.0, player.params.speed_mult_heavy)
	check("corrida: valor coerente com o parâmetro (±3%)", absf(run_speeds[0.42] - expect) < expect * 0.03, "%.1f vs %.1f" % [run_speeds[0.42], expect])
	await place(Vector2(-250.0, 640.0), 0.42)
	act("move_right", true)
	await frames(60)
	var walk_v := player.velocity.x
	act("move_right", false)
	var stop_frames := 0
	while absf(player.velocity.x) > 2.0 and stop_frames < 120:
		await physics_frame
		stop_frames += 1
	check("caminhada: velocidade < corrida e dentro do parâmetro", walk_v < run_speeds[0.42] and absf(walk_v - 230.0 * 1.014) < 12.0, "%.1f" % walk_v)
	check("desaceleração: para em menos de 0,5 s e não instantaneamente", stop_frames > 3 and stop_frames < 30, "%d frames" % stop_frames)
	# mudança de direção
	await place(Vector2(400.0, 640.0), 0.42, 430.0)
	act("move_left", true)
	var turned := -1
	for i in 60:
		await physics_frame
		if player.velocity.x < 0.0:
			turned = i
			break
	act("move_left", false)
	check("mudança de direção: inverte em menos de 0,4 s", turned > 0 and turned < 24, "%d frames" % turned)

	# --- 4. salto: altura por peso e altura variável
	var heights := {}
	for w in [0.1, 0.42, 0.9]:
		var r := await try_jump(Vector2(300.0, 640.0), w, 0, false)
		heights[w] = r["apex_h"]
	check("salto: altura decresce com o peso", heights[0.1] > heights[0.42] and heights[0.42] > heights[0.9], str(heights))
	check("salto: faixas esperadas (leve ~150, normal ~130, pesado ~90)", heights[0.1] > 140.0 and heights[0.1] < 165.0 and heights[0.42] > 120.0 and heights[0.42] < 140.0 and heights[0.9] > 78.0 and heights[0.9] < 100.0, str(heights))
	var short := await try_jump(Vector2(300.0, 640.0), 0.42, 0, false, 0.0, 40, 3)
	check("salto: altura variável (toque curto < salto completo)", short["apex_h"] < heights[0.42] * 0.6, "%.1f vs %.1f" % [short["apex_h"], heights[0.42]])

	# --- 5. coyote time e buffer
	await place(Vector2(940.0, 560.0), 0.42, 0.0)  # topo do ar-condicionado (borda em x=980)
	player.global_position = Vector2(975.0, 560.0)
	player.velocity = Vector2(200.0, 0.0)
	act("move_right", true)
	var left_floor := -1
	for i in 60:
		await physics_frame
		if not player.is_on_floor():
			left_floor = i
			break
	await frames(3)
	act("jump", true)
	await frames(2)
	var vy_after := player.velocity.y
	act("jump", false)
	act("move_right", false)
	check("coyote time: salto aceito poucos frames após sair da borda", left_floor >= 0 and vy_after < -300.0, "vy=%.1f" % vy_after)
	await place(Vector2(300.0, 600.0), 0.42)
	player.velocity = Vector2(0.0, 500.0)
	player.global_position = Vector2(300.0, 600.0)
	act("jump", true)  # pressionado antes de pousar
	await frames(1)
	act("jump", false)
	var buffered_ok := false
	for i in 20:
		await physics_frame
		if player.velocity.y < -300.0:
			buffered_ok = true
			break
	check("jump buffer: salto pressionado antes de pousar é executado", buffered_ok)

	# --- 6. percurso principal: A -> terraço/caixote -> tubo -> torre (alcançável por TODOS os pesos)
	for w in [0.1, 0.42, 0.9]:
		var ok1 := await reach(Vector2(950.0, 560.0), w, 1, Rect2(1140.0, 636.0, 420.0, 70.0))
		check("rota principal: degrau de A cruza o vão até o terraço B (peso %.2f)" % w, ok1)
		var ok2 := await reach(Vector2(1240.0, 700.0), w, 1, top(1290.0, 640.0, 80.0))
		check("rota: terraço -> caixote (peso %.2f)" % w, ok2)
		var ok3 := await reach(Vector2(1350.0, 640.0), w, 1, top(1440.0, 575.0, 120.0))
		check("rota: caixote -> tubo S2 (peso %.2f)" % w, ok3)
		var ok4 := await reach(Vector2(1520.0, 575.0), w, 1, top(1560.0, 520.0, 480.0))
		check("rota: tubo S2 -> topo da torre (peso %.2f)" % w, ok4)

	# --- 7. área opcional H: o peso é ferramenta, nunca bloqueio
	var hl := await reach(Vector2(1930.0, 520.0), 0.10, 0, top(1860.0, 380.0, 130.0))
	var hn := await reach(Vector2(1930.0, 520.0), 0.42, 0, top(1860.0, 380.0, 130.0))
	var hh := await reach(Vector2(1930.0, 520.0), 0.90, 0, top(1860.0, 380.0, 130.0))
	check("opcional H: gato leve alcança a passarela direto", hl)
	check("opcional H: gato normal NÃO alcança direto (nenhum parâmetro de salto)", not hn)
	check("opcional H: gato pesado NÃO alcança direto (nenhum parâmetro de salto)", not hh)
	for w in [0.42, 0.9]:
		var p1 := await reach(Vector2(2020.0, 520.0), w, 1, top(2060.0, 450.0, 90.0))
		check("rota alternativa: torre -> saliência P1 (peso %.2f)" % w, p1)
		var h2 := await reach(Vector2(2070.0, 450.0), w, -1, top(1860.0, 380.0, 130.0))
		check("rota alternativa: P1 -> passarela H (peso %.2f)" % w, h2)

	# --- 8. descida e escada de incêndio (retorno por outro caminho)
	var steps := [[Vector2(1060.0, 940.0), Vector2(1080.0, 880.0), 1], [Vector2(1090.0, 880.0), Vector2(1000.0, 820.0), -1], [Vector2(1000.0, 820.0), Vector2(1090.0, 760.0), 1], [Vector2(1090.0, 760.0), Vector2(1140.0, 700.0), 1]]
	for w in [0.42, 0.9]:
		var okc := 0
		for st in steps:
			var r := await try_jump(st[0], w, st[2], false, 80.0 * st[2], 30)
			if r["ok"] and absf(r["pos"].y - st[1].y) < 4.0:
				okc += 1
		check("escada AB: sobe do beco ao terraço em 4 saltos (peso %.2f)" % w, okc == steps.size(), "%d/%d" % [okc, steps.size()])
	await place(Vector2(1090.0, 880.0), 0.42)
	act("move_down", true)
	act("jump", true)
	await frames(2)
	act("jump", false)
	await frames(30)
	act("move_down", false)
	check("plataforma de mão única: S+Espaço desce", player.global_position.y > 900.0, "y=%.1f" % player.global_position.y)
	await place(Vector2(1090.0, 940.0), 0.42)
	act("jump", true)
	await frames(18)
	act("jump", false)
	await frames(60)
	check("plataforma de mão única: dá para subir atravessando por baixo", player.global_position.y < 890.0, "y=%.1f" % player.global_position.y)

	# --- 9. paredes e bordas
	await place(Vector2(2700.0, 760.0), 0.9)
	act("move_right", true)
	act("run", true)
	await frames(160)
	var xs: Array[float] = []
	for i in 60:
		await physics_frame
		xs.append(player.global_position.x)
	act("move_right", false)
	act("run", false)
	var xspread: float = xs.max() - xs.min()
	check("parede: não atravessa e não treme (x < 2900, variação < 0,5 px)", xs.max() < 2900.0 and xs.min() > 2850.0 and xspread < 0.5, "x=%.1f variação=%.3f" % [xs.max(), xspread])
	await place(Vector2(200.0, 640.0), 0.42)
	act("move_left", true)
	act("run", true)
	await frames(260)
	check("parede esquerda: limite do mundo", player.global_position.x > -280.0, "x=%.1f" % player.global_position.x)
	act("move_left", false)
	act("run", false)
	await place(Vector2(2250.0, 760.0), 0.42, -250.0)
	act("move_left", true)
	await frames(200)
	act("move_left", false)
	check("queda: sai da borda de C e pousa na escada/beco (não atravessa o chão)", player.is_on_floor() and player.global_position.y > 800.0 and player.global_position.y < 905.0, "pos=%s" % str(player.global_position.round()))

	# --- 10. itens e peso (itens novos, para não depender do que outros testes coletaram)
	var items: Node = level.get_node("Items")
	var kib := Area2D.new()
	kib.set_script(load("res://scripts/environment/pickup.gd"))
	kib.set("kind", "kibble")
	kib.position = Vector2(500.0, 610.0)
	items.add_child(kib)
	var can := Area2D.new()
	can.set_script(load("res://scripts/environment/pickup.gd"))
	can.set("kind", "can")
	can.position = Vector2(760.0, 610.0)
	items.add_child(can)
	var k0 := player.kibble
	await place(Vector2(500.0, 640.0), 0.42)
	await frames(6)
	check("ração: coletar aumenta contador e peso (+2%)", player.kibble == k0 + 1 and absf(player.weight - 0.44) < 0.015, "kibble=%d peso=%.3f" % [player.kibble, player.weight])
	await place(Vector2(760.0, 640.0), 0.30)
	await frames(6)
	check("lata: coletar aumenta o peso em ~10%", absf(player.weight - 0.40) < 0.015, "peso=%.3f" % player.weight)
	await place(Vector2(-250.0, 640.0), 0.60)
	var wb := player.weight
	act("move_right", true)
	act("run", true)
	await frames(120)
	act("move_right", false)
	act("run", false)
	check("metabolismo: correr reduz o peso devagar", player.weight < wb and wb - player.weight < 0.02, "%.4f -> %.4f" % [wb, player.weight])

	# --- 11. porta e interação
	var door: Door = level.get_node("Door")
	await place(Vector2(2358.0, 760.0), 0.42)
	act("interact", true)
	await frames(2)
	act("interact", false)
	await frames(60)
	check("porta: E abre e a janela acende", door.want_open and door.open > 0.99, "open=%.2f" % door.open)
	act("interact", true)
	await frames(2)
	act("interact", false)
	await frames(60)
	check("porta: E fecha", (not door.want_open) and door.open < 0.01)

	# --- 11b. localização: interface em inglês, sem texto fixo nos scripts
	TranslationServer.set_locale("en")
	var keys := {}
	var f := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 2 and row[0] != "":
			keys[row[0]] = row[1]
	check("localização: CSV tem as chaves da interface", keys.has("UI_WEIGHT") and keys.has("UI_PAUSED") and keys.size() >= 11, "%d chaves" % keys.size())
	check("localização: tradução em inglês carregada no jogo", TranslationServer.translate("UI_WEIGHT") == "WEIGHT" and TranslationServer.translate("UI_PAUSED") == "PAUSED", TranslationServer.translate("UI_PAUSED"))
	var bad: Array[String] = []
	var cjk_files: Array[String] = []
	var rx := RegEx.new()
	rx.compile("tr\\(\"([A-Z0-9_]+)\"\\)")
	var dir := DirAccess.open("res://scripts/ui")
	for fn in dir.get_files():
		if not fn.ends_with(".gd"):
			continue
		var src := FileAccess.get_file_as_string("res://scripts/ui/" + fn)
		for m in rx.search_all(src):
			if not keys.has(m.get_string(1)):
				bad.append(m.get_string(1))
		for ch in src:
			var code := ch.unicode_at(0)
			if (code >= 0x3040 and code <= 0x30FF) or (code >= 0x4E00 and code <= 0x9FFF):
				cjk_files.append(fn)
				break
	check("localização: toda chave usada na interface existe no CSV", bad.is_empty(), str(bad))
	check("interface: nenhum texto japonês embutido nos scripts de UI", cjk_files.is_empty(), str(cjk_files))
	var hud_font := FontVariation.new()
	hud_font.base_font = load("res://assets/fonts/ZenKakuGothicNew-Medium.ttf")
	hud_font.spacing_glyph = 3
	var footer_w := hud_font.get_string_size(TranslationServer.translate("UI_PAUSE_FOOTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	check("interface: rodapé da pausa cabe no painel (430 px, margens de 36)", footer_w <= 430.0 - 72.0, "%.0f px" % footer_w)
	var band_ok := true
	for w in [0.1, 0.5, 0.9]:
		band_ok = band_ok and keys.has(player.params.band_key(w))
	check("localização: as 3 faixas de peso têm texto", band_ok)

	# --- 12. respawn e câmera
	player.global_position = Vector2(500.0, 1800.0)
	await frames(3)
	check("queda no vazio: reaparece no ponto inicial", player.global_position.distance_to(RooftopLevel.SPAWN) < 5.0, str(player.global_position.round()))
	var cam: Camera2D = main.get_node("Camera")
	await place(Vector2(3000.0, 380.0), 0.42)
	player.global_position = Vector2(2880.0, 760.0)
	await frames(240)
	var half_w := 640.0 / cam.zoom.x
	check("câmera: respeita o limite direito", cam.get_screen_center_position().x + half_w <= RooftopLevel.CAMERA_LIMITS.end.x + 2.0, "centro=%.1f" % cam.get_screen_center_position().x)
	await place(Vector2(200.0, 640.0), 0.42)
	await frames(200)
	check("câmera: respeita o limite esquerdo", cam.get_screen_center_position().x - half_w >= RooftopLevel.CAMERA_LIMITS.position.x - 2.0)
	check("pose: parado é IDLE", player.pose == Player.Pose.IDLE)
