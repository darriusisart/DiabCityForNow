extends Node3D

@export var player: CharacterBody3D
@export var follow_speed := 8.0
@export var camera_height := 6.0
@export var camera_distance := 8.0

@onready var camera: Camera3D = $Camera3D

func _ready():
	camera.current = true
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.look_at(global_position + Vector3.UP * 1.5, Vector3.UP)

func _process(delta):
	if player == null:
		return

	global_position = global_position.lerp(player.global_position, follow_speed * delta)

	camera.look_at(player.global_position + Vector3.UP * 1.5, Vector3.UP)
