extends Node3D

@onready var area = $Area3D
@onready var dialogue = $Label3D

var player_in_range = false

var temp_dialogue_lines = [
	"Hi! I'm Suki!\n[E]",
	"I'm being used for NPC testing!\n[E]",
	"You can press E to continue talking.\n[E]",
	"Madi wrote this :)\n[E]",
	"That's all I have to say!"
]

var dialogue_index = 0
var dialogue_active = false

func _ready():
	dialogue.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):

		if !dialogue_active:
			dialogue_active = true
			dialogue_index = 0
			dialogue.visible = true
			dialogue.text = temp_dialogue_lines[dialogue_index]

		else:
			dialogue_index += 1

			if dialogue_index < temp_dialogue_lines.size():
				dialogue.text = temp_dialogue_lines[dialogue_index]
			else:
				dialogue.visible = false
				dialogue_active = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		dialogue.visible = true
		dialogue.text = "[E]"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		dialogue.visible = false

		dialogue_active = false
		dialogue_index = 0
