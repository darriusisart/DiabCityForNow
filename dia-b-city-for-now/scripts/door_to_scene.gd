extends Node3D

@export_file("*.tscn") var scene_path := "res://Scenes/convenienceStore/cardmain.tscn"
func interact(_player: Node) -> void:
	print("jk")
	get_tree().change_scene_to_file(scene_path)
