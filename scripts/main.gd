extends Node2D
## Cena principal: liga jogador, câmera, HUD e áudio. Sem lógica de jogo própria.

@onready var level: RooftopLevel = $Level
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	player.global_position = RooftopLevel.SPAWN
	player.spawn_point = RooftopLevel.SPAWN
	var lim := RooftopLevel.CAMERA_LIMITS
	camera.limit_left = int(lim.position.x)
	camera.limit_top = int(lim.position.y)
	camera.limit_right = int(lim.end.x)
	camera.limit_bottom = int(lim.end.y)
	camera.zoom = Vector2(1.15, 1.15)
	camera.target = player
	camera.snap()
	hud.bind(player)
	var audio := Node.new()
	audio.set_script(load("res://scripts/systems/game_audio.gd"))
	audio.name = "GameAudio"
	add_child(audio)
	audio.setup(player, level.get_node("Door"))
