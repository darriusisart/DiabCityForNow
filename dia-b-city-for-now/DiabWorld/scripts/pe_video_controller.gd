extends Node2D

@export var min_watch_seconds: float = 45.0
@export_file("*.tscn") var exit_scene_path: String = "res://DiabWorld/scenes/Recess_World.tscn"
@export var completion_step_id: String = "pe"
@export var dance_prompt_text: String = "Dance along with the video for at least a few seconds!"
@export var dance_prompt_hold_seconds: float = 4.0

@onready var video: VideoStreamPlayer = $VideoStreamPlayer

var _exit_built: bool = false

func _ready() -> void:
	_build_dance_prompt()
	video.finished.connect(_on_video_finished)
	if min_watch_seconds <= 0.0:
		return
	var timer: SceneTreeTimer = get_tree().create_timer(min_watch_seconds)
	timer.timeout.connect(_on_watch_minimum_met)

func _build_dance_prompt() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 70
	add_child(layer)

	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var label: Label = Label.new()
	label.text = dance_prompt_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 18.0
	label.offset_bottom = 86.0
	label.add_theme_font_size_override("font_size", 30)
	root.add_child(label)

	await get_tree().create_timer(max(0.1, dance_prompt_hold_seconds)).timeout
	if is_instance_valid(layer):
		layer.queue_free()

func _on_watch_minimum_met() -> void:
	if video != null and video.is_playing():
		return
	_on_video_finished()

func _on_video_finished() -> void:
	if _exit_built:
		return
	_exit_built = true
	_build_exit_overlay()

func _build_exit_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 80
	add_child(layer)

	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_top = -100.0
	panel.offset_right = 260.0
	panel.offset_bottom = 100.0
	root.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var msg: Label = Label.new()
	msg.text = "Nice dancing! When you are ready, continue back to school."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)

	var btn: Button = Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn)

func _on_continue_pressed() -> void:
	var df: Node = Data.day_flow()
	if completion_step_id != "" and df != null and df.has_method("complete_step"):
		df.complete_step(completion_step_id)
	get_tree().change_scene_to_file(exit_scene_path)
