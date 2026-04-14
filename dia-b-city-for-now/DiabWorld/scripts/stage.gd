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
	if df == null or not df.has_method("get_time_of_day"):
		return
	var tod := String(df.get_time_of_day()).to_lower()
	var env_energy := 0.85
	var ambient := 0.22
	var sun_energy := 1.1
	var sun_color := Color(1.0, 0.98, 0.92, 1.0)
	if tod.find("afternoon") >= 0:
		env_energy = 0.72
		ambient = 0.18
		sun_energy = 0.95
		sun_color = Color(1.0, 0.9, 0.74, 1.0)
	elif tod.find("after school") >= 0:
		env_energy = 0.56
		ambient = 0.14
		sun_energy = 0.78
		sun_color = Color(0.96, 0.72, 0.56, 1.0)
	elif tod.find("evening") >= 0:
		env_energy = 0.42
		ambient = 0.1
		sun_energy = 0.62
		sun_color = Color(0.7, 0.72, 0.92, 1.0)
	if _world_environment != null and _world_environment.environment != null:
		_world_environment.environment.background_energy_multiplier = env_energy
		_world_environment.environment.ambient_light_energy = ambient
	if _sun_light != null:
		_sun_light.light_energy = sun_energy
		_sun_light.light_color = sun_color
