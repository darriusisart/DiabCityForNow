@tool
extends MeshInstance3D

@onready var cam: Camera3D = get_parent()

func _process(_delta):
	var dist = 1.0
	position = Vector3(0, 0, -dist)
	var fov_rad = deg_to_rad(cam.fov)
	var height = 2.0 * dist * tan(fov_rad / 2.0)
	var width = height * cam.get_viewport().size.aspect()
	mesh.size = Vector2(width, height)
