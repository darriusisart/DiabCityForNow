extends Area3D

@export_file("*.tscn") var destination_scene: String

func _ready():
	print("PORTAL SCRIPT LOADED")

func _on_body_entered(body):
	if body.is_in_group("player"):
		if destination_scene != "":
			SceneManager.go_to_minigame(destination_scene)
