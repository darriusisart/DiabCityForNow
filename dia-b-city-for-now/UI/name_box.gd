extends Panel

@onready var margin_container = $MarginContainer
@onready var name_label = $MarginContainer/NameLabel

func _ready():
	await set_speaker_name(name_label.text)

func set_speaker_name(new_name: String):
	name_label.text = new_name
	await get_tree().process_frame

	size = margin_container.get_combined_minimum_size()
