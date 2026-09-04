extends Area3D

@export_file("*.tscn") var destination_scene: String

func _on_body_entered(body):
	print("PORTAL DETECTED:", body.name)

	if body.is_in_group("player"):
		print("PLAYER ENTERED PORTAL")

		if destination_scene != "":
			print("DESTINATION:", destination_scene)
			SceneManager.go_to_minigame(destination_scene)
