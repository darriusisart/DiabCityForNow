extends Node3D

@export var player_path: NodePath
@export var follow_speed := 8.0
@export var fixed_height := 6.0
@export var z_offset := 7.0

@onready var player: Node3D = get_node(player_path)

func _process(delta: float) -> void:
	if player == null:
		return

	var target_position := Vector3(
		player.global_position.x,
		fixed_height,
		player.global_position.z + z_offset
	)

	global_position = global_position.lerp(target_position, follow_speed * delta)
