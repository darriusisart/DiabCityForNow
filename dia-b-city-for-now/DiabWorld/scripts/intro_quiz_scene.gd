extends Control

@export_file("*.tscn") var next_scene_path: String = "res://DiabWorld/scenes/home_world.tscn"

@onready var quiz: CanvasLayer = $BeginQuiz

func _ready() -> void:
	if quiz.has_signal("quiz_finished"):
		quiz.quiz_finished.connect(_on_quiz_finished)
	if quiz.has_method("start_standalone"):
		quiz.start_standalone()

func _on_quiz_finished() -> void:
	get_tree().change_scene_to_file(next_scene_path)
