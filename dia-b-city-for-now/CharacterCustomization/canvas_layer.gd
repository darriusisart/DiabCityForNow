extends CanvasLayer

@export var eyeColorPicker:Control

var eyeColorPopup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("deferred_ready")

func deferred_ready():
	eyeColorPicker.set_edit_alpha(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_eye_color_picker_picker_created() -> void:
	eyeColorPopup = eyeColorPicker.get_popup()
	#reposition_popup(eyeColorPopup)


# Color is applied via Player._on_eye_color_picker_color_changed (signal connected to Player)
