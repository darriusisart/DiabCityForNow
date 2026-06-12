extends Node3D

@export var player: CharacterBody3D
@export var follow_speed := 8.0
@export var camera_height := 6.0
@export var camera_distance := 8.0

@export var normal_fov := 75.0
@export var dialogue_fov := 55.0
@export var zoom_time := 0.35

@onready var camera: Camera3D = $Camera

var zoom_tween: Tween

func _ready():
	camera.current = true
	camera.fov = normal_fov
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.look_at(global_position + Vector3.UP * 1.5, Vector3.UP)

func _process(delta):
	if player == null:
		return

	global_position = global_position.lerp(player.global_position, follow_speed * delta)

	camera.look_at(player.global_position + Vector3.UP * 1.5, Vector3.UP)

func zoom_in_dialogue():
	if zoom_tween:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "fov", dialogue_fov, zoom_time)

func zoom_out_dialogue():
	if zoom_tween:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "fov", normal_fov, zoom_time)
