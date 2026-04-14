extends Node3D

@export_file("*.tscn") var sleep_minigame_scene: String = "res://DiabWorld/scenes/ui/counting_sheep_minigame.tscn"

func interact(_player: Node) -> void:
	get_tree().change_scene_to_file(sleep_minigame_scene)
