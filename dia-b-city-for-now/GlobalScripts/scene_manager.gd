extends Node

var previous_scene_path: String = ""

func go_to_minigame(minigame_path: String):
	previous_scene_path = get_tree().current_scene.scene_file_path
	print("Saved previous scene: ", previous_scene_path)

	get_tree().change_scene_to_file(minigame_path)

func return_to_previous_scene():
	print("Previous scene currently stored as: ", previous_scene_path)

	if previous_scene_path != "":
		get_tree().change_scene_to_file(previous_scene_path)
	else:
		print("ERROR: previous_scene_path is empty")
