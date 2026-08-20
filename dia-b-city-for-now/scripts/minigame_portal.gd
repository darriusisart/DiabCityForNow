extends Area3D

@export_file("*.tscn") var destination_scene: String

func _on_body_entered(body):
	if body.is_in_group("player"):
		if destination_scene != "":
			get_tree().change_scene_to_file(destination_scene)
