extends SceneTree
## Captura de tela real da execução. Uso: godot --path . -s tools/shot.gd -- saida.png [frames]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "res://screenshots/shot.png"
	var frames: int = int(args[1]) if args.size() > 1 else 90
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("CAPTURA ", out, " ", img.get_size())
	quit()
