extends Control

@onready var panel = $Panel
@onready var name_box = $Panel/NameBox
@onready var portrait = $Panel/PortraitFrame/Portrait
@onready var dialogue_text = $Panel/DialogueText
@onready var continue_label = $Panel/ContinueLabel
@onready var blip_sound = $Panel/BlipSound
@onready var camera_rig = get_tree().current_scene.get_node("CameraRig")

@export var blip_every_letters := 4
@export var text_speed := 0.03

var lines = []
var index := 0
var active := false
var typing := false
var current_text := ""

func _ready():
	panel.visible = false

func start_dialogue(new_lines: Array):
	lines = new_lines
	index = 0
	active = true
	panel.visible = true
	_show_line()
	camera_rig.zoom_in_dialogue()

func advance_dialogue():
	if !active:
		return

	if typing:
		_finish_typing()
		return

	index += 1

	if index < lines.size():
		_show_line()
	else:
		end_dialogue()

func end_dialogue():
	panel.visible = false
	active = false
	index = 0
	typing = false
	camera_rig.zoom_out_dialogue()

func _show_line():
	var line = lines[index]

	name_box.set_speaker_name(line["name"])
	current_text = line["text"]

	dialogue_text.text = ""
	continue_label.visible = false

	if line.has("portrait") and line["portrait"] != null:
		portrait.texture = line["portrait"]

	_type_text()

func _type_text():
	typing = true

	for i in current_text.length():
		if !typing:
			return

		dialogue_text.text += current_text[i]

		if i % blip_every_letters == 0 and current_text[i] != " ":
			blip_sound.play()

		await get_tree().create_timer(text_speed).timeout

	typing = false
	continue_label.visible = true

func _finish_typing():
	typing = false
	dialogue_text.text = current_text
	continue_label.visible = true
