extends Control

@onready var panel = $Panel
@onready var name_box = $Panel/NameBox
@onready var portrait = $Panel/PortraitFrame/Portrait
@onready var dialogue_text = $Panel/DialogueText
@onready var continue_label = $Panel/ContinueLabel

var lines = []
var index := 0
var active := false

func _ready():
	panel.visible = false

func start_dialogue(new_lines: Array):
	lines = new_lines
	index = 0
	active = true
	panel.visible = true
	_show_line()

func advance_dialogue():
	if !active:
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

func _show_line():
	var line = lines[index]

	name_box.set_speaker_name(line["name"])
	dialogue_text.text = line["text"]

	if line.has("portrait") and line["portrait"] != null:
		portrait.texture = line["portrait"]
