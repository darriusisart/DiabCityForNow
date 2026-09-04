extends Node2D

@onready var exit_button: Button = $UI/ExitButton

func _ready():
	exit_button.pressed.connect(_on_exit_button_pressed)

func _on_exit_button_pressed():
	print("EXIT BUTTON PRESSED")
	SceneManager.return_to_previous_scene()
