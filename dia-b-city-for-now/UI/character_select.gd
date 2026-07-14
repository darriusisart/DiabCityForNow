extends Node

var selected_character := "west"

@onready var west_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/WestButton
@onready var suki_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/SukiButton
@onready var beau_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/BeauButton
@onready var start_button = $CanvasLayer/Control/VBoxContainer/StartButton
@onready var selected_label = $CanvasLayer/Control/VBoxContainer/SelectedLabel

func _ready():
	west_button.pressed.connect(_on_west_pressed)
	suki_button.pressed.connect(_on_suki_pressed)
	beau_button.pressed.connect(_on_beau_pressed)
	start_button.pressed.connect(_on_start_pressed)

	selected_label.text = "Selected: West"

func _on_west_pressed():
	selected_character = "west"
	selected_label.text = "Selected: West"
	print("Selected West")

func _on_suki_pressed():
	selected_character = "suki"
	selected_label.text = "Selected: Suki"
	print("Selected Suki")
	
func _on_beau_pressed():
	selected_character = "beau"
	selected_label.text = "Selected: Beau"
	print("Selected Beau")

func _on_start_pressed():
	Global.selected_character = selected_character
	get_tree().change_scene_to_file("res://Scenes/levels/MadisonTestScene.tscn")
