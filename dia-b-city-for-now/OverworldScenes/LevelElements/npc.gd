extends Node3D

@onready var area = $Area3D
@onready var prompt = $Label3D
@onready var dialogue_box = get_tree().current_scene.get_node("DialogueBox")

@export var suki_neutral: Texture2D
@export var suki_happy: Texture2D

var player_in_range := false

var dialogue_lines := []

func _ready():
	prompt.visible = false

	dialogue_lines = [
		{
			"name": "Suki",
			"text": "Hi! I'm Suki!",
			"portrait": suki_happy
		},
		{
			"name": "Suki",
			"text": "I'm being used for NPC testing! These are temporary portrait images...",
			"portrait": suki_neutral
		},
		{
			"name": "Suki",
			"text": "You can press E to continue talking.",
			"portrait": suki_neutral
		},
		{
			"name": "Suki",
			"text": "Madi wrote this :)",
			"portrait": suki_happy
		},
		{
			"name": "Suki",
			"text": "That's all I have to say!",
			"portrait": suki_neutral
		}
	]

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		prompt.visible = false

		if !dialogue_box.active:
			dialogue_box.start_dialogue(dialogue_lines)
		else:
			dialogue_box.advance_dialogue()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		prompt.visible = true
		prompt.text = "[E]"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		prompt.visible = false
		dialogue_box.end_dialogue()
