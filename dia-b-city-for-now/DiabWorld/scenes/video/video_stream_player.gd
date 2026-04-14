extends VideoStreamPlayer

@onready var btn = $"../Pause"

#var loop: bool

func _on_pause_button_down() -> void:
	paused = !paused
	if paused:
		btn.text = "Play"
	else:
		btn.text = "Pause"

#
#func _on_loop_button_down() -> void:
	#loop = !loop
