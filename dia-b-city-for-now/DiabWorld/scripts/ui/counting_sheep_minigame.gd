extends Control

@export var sheep_goal: int = 10
@export_file("*.tscn") var return_scene_path: String = "res://DiabWorld/scenes/home_world.tscn"

const SHEEP_TEX := preload("res://assets_Shreya/SHEEP_Shreya.png")

@onready var _count_label: Label = $VBox/CountLabel
@onready var _hint_label: Label = $VBox/HintLabel
@onready var _sheep_field: Control = $SheepField

var _count: int = 0
var _finished: bool = false

func _ready() -> void:
	_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_count_sheep()
		get_viewport().set_input_as_handled()

func _on_count_sheep() -> void:
	if _finished:
		return
	_count += 1
	_spawn_sheep_hop()
	_update_labels()
	if _count >= sheep_goal:
		_finished = true
		_hint_label.text = "Sweet dreams…"
		await get_tree().create_timer(1.4).timeout
		_apply_sleep_rewards()
		get_tree().change_scene_to_file(return_scene_path)

func _update_labels() -> void:
	_count_label.text = "Sheep counted: %d / %d" % [_count, sheep_goal]

func _spawn_sheep_hop() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var tr: TextureRect = TextureRect.new()
	tr.texture = SHEEP_TEX
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(200, 200)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_y: float = randf_range(vp.y * 0.25, vp.y * 0.55)
	tr.position = Vector2(-240.0, base_y)
	_sheep_field.add_child(tr)

	var end_pos: Vector2 = Vector2(vp.x + 240.0, base_y - 70.0)
	var tw: Tween = create_tween()
	tw.tween_property(tr, "position", end_pos, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		if is_instance_valid(tr):
			tr.queue_free()
	)

func _apply_sleep_rewards() -> void:
	var pl: Node = Data.pillars()
	if pl != null and pl.has_method("add_xp"):
		pl.add_xp("sleep", 8, "sleep_reset")
	var df: Node = Data.day_flow()
	if df == null:
		return
	var current_step := ""
	if df.has_method("get_current_step"):
		current_step = str(df.get_current_step())
	var sleeping_after_afternoon := current_step in ["recess", "lunch", "store", "home"]
	if sleeping_after_afternoon and df.has_method("reset_to_morning"):
		df.reset_to_morning()
	elif df.has_method("complete_step"):
		df.complete_step("home")
