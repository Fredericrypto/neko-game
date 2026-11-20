class_name RooftopLevel
extends Node2D
## Pequena área de telhados. Os dados abaixo são a fonte única de colisão e de desenho.
## Medidas em pixels do mundo (y cresce para baixo). Alturas conferidas por testes de salto.

const SKIN_INK := "ink"
const SKIN_CHARCOAL := "charcoal"
const SKIN_STONE := "stone"
const SKIN_MID := "mid"

## [x, y_topo, largura, altura, skin, nome]
const SOLIDS: Array = [
	[-340.0, -300.0, 60.0, 2000.0, SKIN_INK, "parede_esquerda"],
	[-300.0, 640.0, 1280.0, 900.0, SKIN_STONE, "A_telhado_inicial"],
	[540.0, 572.0, 100.0, 68.0, "vent", "A_caixa_ventilacao"],
	[820.0, 600.0, 80.0, 40.0, "ac", "A_ar_condicionado_1"],
	[900.0, 560.0, 80.0, 80.0, "ac", "A_ar_condicionado_2"],
	[980.0, 940.0, 160.0, 600.0, SKIN_INK, "beco_AB_piso"],
	[1140.0, 700.0, 420.0, 800.0, SKIN_CHARCOAL, "B_terraco"],
	[1290.0, 640.0, 80.0, 60.0, "crate", "B_caixote"],
	[1560.0, 520.0, 480.0, 1000.0, SKIN_INK, "B_torre"],
	[2040.0, 900.0, 180.0, 600.0, SKIN_INK, "beco_BC_piso"],
	[2220.0, 760.0, 680.0, 800.0, SKIN_MID, "C_telhado"],
	[2300.0, 660.0, 130.0, 100.0, "house", "C_casa_escada"],
	[2440.0, 720.0, 60.0, 40.0, "crate", "C_caixote"],
	[2660.0, 720.0, 80.0, 40.0, "fanbox", "C_caixa_ventilador"],
	[2900.0, 380.0, 340.0, 1300.0, SKIN_INK, "X_predio_final"],
]

## [x, y_topo, largura, nome] — plataformas de mão única (escada de incêndio, saliências)
const ONEWAYS: Array = [
	[1040.0, 880.0, 100.0, "esc_AB_1"], [980.0, 820.0, 100.0, "esc_AB_2"],
	[1040.0, 760.0, 100.0, "esc_AB_3"], [980.0, 700.0, 100.0, "esc_AB_4"],
	[2120.0, 835.0, 100.0, "esc_BC_1"], [2040.0, 770.0, 100.0, "esc_BC_2"],
	[2120.0, 705.0, 100.0, "esc_BC_3"], [2040.0, 640.0, 100.0, "esc_BC_4"],
	[2120.0, 575.0, 100.0, "esc_BC_5"],
	[1440.0, 575.0, 120.0, "S2_tubo"],
	[2060.0, 450.0, 90.0, "P1_saliencia"],
	[1860.0, 380.0, 130.0, "H_passarela"],
]

## Itens: [tipo, x, y]
const ITEMS: Array = [
	["kibble", 1010.0, 575.0], ["kibble", 1050.0, 548.0], ["kibble", 1090.0, 548.0], ["kibble", 1125.0, 575.0],
	["kibble", 1230.0, 668.0], ["kibble", 1330.0, 608.0], ["kibble", 1500.0, 545.0],
	["kibble", 1620.0, 490.0], ["kibble", 1700.0, 490.0], ["kibble", 1790.0, 490.0],
	["kibble", 2105.0, 418.0], ["kibble", 2010.0, 360.0], ["kibble", 1890.0, 350.0],
	["can", 1925.0, 350.0], ["kibble", 1960.0, 350.0],
	["kibble", 1100.0, 850.0], ["kibble", 1030.0, 790.0], ["kibble", 1100.0, 730.0], ["kibble", 1030.0, 670.0],
	["kibble", 2170.0, 805.0], ["kibble", 2090.0, 740.0], ["kibble", 2170.0, 675.0], ["kibble", 2090.0, 610.0],
	["kibble", 2540.0, 730.0], ["kibble", 2600.0, 730.0], ["kibble", 2360.0, 628.0], ["kibble", 2400.0, 628.0],
]

const SPAWN := Vector2(220.0, 640.0)
const DOOR_POS := Vector2(2358.0, 760.0)
const CAMERA_LIMITS := Rect2(-100.0, 120.0, 3300.0, 1000.0)

var solid_body: StaticBody2D
var oneway_body: StaticBody2D

func _ready() -> void:
	_build_collision()
	var far := _parallax(0.12, Vector2(0.18, 1.0), -40, 0)
	var mid := _parallax(0.30, Vector2(0.45, 1.0), -30, 1)
	var sky := Node2D.new()
	sky.set_script(load("res://scripts/environment/sky_backdrop.gd"))
	sky.z_index = -60
	add_child(sky)
	add_child(far)
	add_child(mid)
	var art := Node2D.new()
	art.name = "Facades"
	art.set_script(load("res://scripts/environment/facade_art.gd"))
	art.z_index = -5
	add_child(art)
	var life := Node2D.new()
	life.name = "AmbientLife"
	life.set_script(load("res://scripts/environment/ambient_life.gd"))
	life.z_index = -2
	add_child(life)
	var front := Node2D.new()
	front.name = "Foreground"
	front.set_script(load("res://scripts/environment/foreground_art.gd"))
	front.z_index = 30
	add_child(front)
	var items := Node2D.new()
	items.name = "Items"
	add_child(items)
	for it in ITEMS:
		var pk := Area2D.new()
		pk.set_script(load("res://scripts/environment/pickup.gd"))
		pk.set("kind", it[0])
		pk.position = Vector2(it[1], it[2])
		items.add_child(pk)
	var door := Area2D.new()
	door.name = "Door"
	door.set_script(load("res://scripts/environment/door.gd"))
	door.position = DOOR_POS
	add_child(door)

func _parallax(_unused: float, scroll: Vector2, z: int, kind: int) -> Parallax2D:
	var px := Parallax2D.new()
	px.scroll_scale = scroll
	px.z_index = z
	var city := Node2D.new()
	city.set_script(load("res://scripts/environment/city_layer.gd"))
	city.set("kind", kind)
	px.add_child(city)
	return px

func _build_collision() -> void:
	solid_body = StaticBody2D.new()
	solid_body.name = "Solids"
	solid_body.collision_layer = 1
	solid_body.collision_mask = 0
	add_child(solid_body)
	for s in SOLIDS:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(s[2], s[3])
		cs.shape = rs
		cs.position = Vector2(s[0] + s[2] * 0.5, s[1] + s[3] * 0.5)
		cs.name = s[5]
		solid_body.add_child(cs)
	oneway_body = StaticBody2D.new()
	oneway_body.name = "OneWays"
	oneway_body.collision_layer = 4
	oneway_body.collision_mask = 0
	add_child(oneway_body)
	for o in ONEWAYS:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(o[2], 10.0)
		cs.shape = rs
		cs.one_way_collision = true
		cs.one_way_collision_margin = 6.0
		cs.position = Vector2(o[0] + o[2] * 0.5, o[1] + 5.0)
		cs.name = o[3]
		oneway_body.add_child(cs)
