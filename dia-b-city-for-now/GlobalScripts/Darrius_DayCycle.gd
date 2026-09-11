extends Node3D

@export var portals:Array[Node3D] = []
@export var player:CharacterBody3D
@export var auto_adjust_day_lighting := true

var _world_environment: WorldEnvironment
var _sun_light: DirectionalLight3D

func _ready():
	StageManager.new_scene_loaded(portals,player)
	if auto_adjust_day_lighting:
		_world_environment = get_node_or_null("WorldEnvironment")
		_sun_light = get_node_or_null("DirectionalLight3D")
		_apply_day_lighting()

func _process(_delta: float) -> void:
	if auto_adjust_day_lighting:
		_apply_day_lighting()

func _apply_day_lighting() -> void:
	var df: Node = Data.day_flow()
	if df == null or not df.has_method("get_day_progress"):
		return
	var p := clampf(float(df.get_day_progress()), 0.0, 1.0)
	var env_energy := lerpf(0.92, 0.34, p)
	var ambient := lerpf(0.24, 0.08, p)
	var sun_energy := lerpf(1.12, 0.52, p)
	var sun_color := Color(1.0, 0.98, 0.92, 1.0).lerp(Color(0.68, 0.72, 0.92, 1.0), p)
	if _world_environment != null and _world_environment.environment != null:
		_world_environment.environment.background_energy_multiplier = env_energy
		_world_environment.environment.ambient_light_energy = ambient
	if _sun_light != null:
		_sun_light.light_energy = sun_energy
		_sun_light.light_color = sun_color
