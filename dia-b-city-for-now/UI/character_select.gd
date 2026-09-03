extends Node

var selected_character := "west"

@onready var west_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/WestButton
@onready var suki_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/SukiButton
@onready var beau_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/BeauButton
@onready var jodie_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer/JodieButton
@onready var nia_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer2/NiaButton
@onready var leena_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer2/LeenaButton
@onready var cas_button = $CanvasLayer/Control/VBoxContainer/HBoxContainer2/CasButton
@onready var start_button = $CanvasLayer/Control/VBoxContainer/StartButton
@onready var selected_label = $CanvasLayer/Control/VBoxContainer/SelectedLabel

const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TIME := 0.12

var hover_tweens: Dictionary = {}

func _ready():
	west_button.pressed.connect(_on_west_pressed)
	suki_button.pressed.connect(_on_suki_pressed)
	beau_button.pressed.connect(_on_beau_pressed)
	jodie_button.pressed.connect(_on_jodie_pressed)
	nia_button.pressed.connect(_on_nia_pressed)
	leena_button.pressed.connect(_on_leena_pressed)
	cas_button.pressed.connect(_on_cas_pressed)
	start_button.pressed.connect(_on_start_pressed)

	await get_tree().process_frame

	for button in [west_button, suki_button, beau_button, jodie_button, nia_button, leena_button, cas_button, start_button]:
		button.pivot_offset = button.size / 2.0

	selected_label.text = "Selected: "
	
func animate_button(button: Control, target_scale: Vector2) -> void:
	if hover_tweens.has(button):
		var old_tween: Tween = hover_tweens[button]

		if old_tween and old_tween.is_valid():
			old_tween.kill()

	var tween := create_tween()
	hover_tweens[button] = tween

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, HOVER_TIME)
	
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
	
func _on_jodie_pressed():
	selected_character = "jodie"
	selected_label.text = "Selected: Jodie"
	print("Selected Jodie")
	
func _on_nia_pressed():
	selected_character = "nia"
	selected_label.text = "Selected: Nia"
	print("Selected Nia")
	
func _on_leena_pressed():
	selected_character = "leena"
	selected_label.text = "Selected: Leena"
	print("Selected Leena")
	
func _on_cas_pressed():
	selected_character = "cas"
	selected_label.text = "Selected: Cas"
	print("Selected Cas")
	
func _on_start_pressed():
	Global.selected_character = selected_character
	get_tree().change_scene_to_file("res://Scenes/levels/MadisonTestScene.tscn")


func _on_suki_button_mouse_entered() -> void:
	animate_button(suki_button, HOVER_SCALE)


func _on_suki_button_mouse_exited() -> void:
	animate_button(suki_button, Vector2.ONE)


func _on_west_button_mouse_entered() -> void:
	animate_button(west_button, HOVER_SCALE)


func _on_west_button_mouse_exited() -> void:
	animate_button(west_button, Vector2.ONE)


func _on_beau_button_mouse_entered() -> void:
	animate_button(beau_button, HOVER_SCALE)


func _on_beau_button_mouse_exited() -> void:
	animate_button(beau_button, Vector2.ONE)


func _on_jodie_button_mouse_entered() -> void:
	animate_button(jodie_button, HOVER_SCALE)


func _on_jodie_button_mouse_exited() -> void:
	animate_button(jodie_button, Vector2.ONE)


func _on_start_button_mouse_entered() -> void:
	animate_button(start_button, HOVER_SCALE)


func _on_start_button_mouse_exited() -> void:
	animate_button(start_button, Vector2.ONE)


func _on_nia_button_mouse_entered() -> void:
	animate_button(nia_button, HOVER_SCALE)


func _on_nia_button_mouse_exited() -> void:
	animate_button(nia_button, Vector2.ONE)


func _on_leena_button_mouse_entered() -> void:
	animate_button(leena_button, HOVER_SCALE)

func _on_leena_button_mouse_exited() -> void:
	animate_button(leena_button, Vector2.ONE)


func _on_cas_button_mouse_entered() -> void:
	animate_button(cas_button, HOVER_SCALE)


func _on_cas_button_mouse_exited() -> void:
	animate_button(cas_button, Vector2.ONE)
