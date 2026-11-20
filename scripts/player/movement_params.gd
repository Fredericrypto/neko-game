class_name MovementParams
extends Resource
## Parâmetros de movimento do gato. TODOS os valores são provisórios (ajustados por teste
## e por sensação de jogo). As faixas de peso aguardam a decisão D-001.

@export_group("Chão")
@export var walk_speed := 230.0
@export var run_speed := 430.0
@export var ground_accel := 2100.0
@export var ground_decel := 2500.0
@export var turn_decel := 4200.0
@export var skid_speed := 260.0

@export_group("Ar")
@export var air_accel := 1500.0
@export var air_drag := 500.0
@export var gravity := 2400.0
@export var fall_gravity_mult := 1.35
@export var apex_window := 90.0
@export var apex_gravity_mult := 0.62
@export var max_fall_speed := 1150.0

@export_group("Salto")
@export var jump_speed := 780.0
@export var jump_cut := 0.45
@export var coyote_time := 0.10
@export var jump_buffer := 0.12

@export_group("Peso (provisório, D-001)")
@export var band_light_max := 0.30
@export var band_normal_max := 0.65
@export var start_weight := 0.42
@export var speed_mult_light := 1.08
@export var speed_mult_heavy := 0.84
@export var accel_mult_light := 1.15
@export var accel_mult_heavy := 0.72
@export var jump_mult_light := 1.10
@export var jump_mult_heavy := 0.86
@export var gravity_mult_light := 1.0
@export var gravity_mult_heavy := 1.05
@export var weight_test_rate := 0.30
@export var kibble_weight := 0.02
@export var can_weight := 0.10
@export var burn_run := 0.004
@export var burn_walk := 0.0008

@export_group("Animação")
@export var stride_rate := 0.045
@export var land_recovery := 0.16

## Interpola um valor entre três âncoras (leve, normal, pesado) usando o peso contínuo 0..1.
## As âncoras ficam no centro de cada faixa provisória.
func sample(w: float, light: float, normal: float, heavy: float) -> float:
	var c_l := band_light_max * 0.5
	var c_n := (band_light_max + band_normal_max) * 0.5
	var c_h := (band_normal_max + 1.0) * 0.5
	if w <= c_l:
		return light
	if w <= c_n:
		return lerpf(light, normal, (w - c_l) / (c_n - c_l))
	if w <= c_h:
		return lerpf(normal, heavy, (w - c_n) / (c_h - c_n))
	return heavy

func band_name(w: float) -> String:
	if w <= band_light_max:
		return "LIGHT"
	if w <= band_normal_max:
		return "NORMAL"
	return "HEAVY"
