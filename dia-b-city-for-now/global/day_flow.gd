extends Node

const STEP_WAKE_UP := "wake_up"
const STEP_CALENDAR := "calendar"
const STEP_GO_TO_SCHOOL := "go_to_school"
const STEP_CLASS := "class"
const STEP_PE := "pe"
const STEP_LUNCH := "lunch"
const STEP_RECESS := "recess"
const STEP_STORE := "store"
const STEP_HOME := "home"

const ORDERED_STEPS := [
	STEP_WAKE_UP,
	STEP_CALENDAR,
	STEP_GO_TO_SCHOOL,
	STEP_CLASS,
	STEP_PE,
	STEP_RECESS,
	STEP_LUNCH,
	STEP_STORE,
	STEP_HOME
]

var strict_mode := true
var allow_revisit_completed := true
var show_begin_quiz := false
var current_step_index := 0
var completed_steps: PackedStringArray = []
var time_of_day := "Morning"
var _pending_location_label := ""
var _daily_once_flags := {}

const STEP_TIME_OF_DAY := {
	STEP_WAKE_UP: "Early Morning",
	STEP_CALENDAR: "Morning",
	STEP_GO_TO_SCHOOL: "Morning",
	STEP_CLASS: "Late Morning",
	STEP_PE: "Noon",
	STEP_RECESS: "Afternoon",
	STEP_LUNCH: "Late Afternoon",
	STEP_STORE: "After School",
	STEP_HOME: "Evening"
}

const LOCATION_NAME_OVERRIDES := {
	"classroom": "Classroom",
	"pe_classroom": "PE Room",
	"pe_video": "PE Studio",
	"school_world": "School Hall",
	"recess_world": "Recess Yard",
	"home_world": "Home",
	"convenience_world": "Convenience Store"
}

func _ready() -> void:
	_update_time_of_day_from_step()
	var tree := get_tree()
	if tree == null:
		return
	if tree.has_signal("current_scene_changed"):
		if not tree.is_connected("current_scene_changed", Callable(self, "_on_current_scene_changed")):
			tree.connect("current_scene_changed", Callable(self, "_on_current_scene_changed"))
	elif tree.has_signal("scene_changed"):
		if not tree.is_connected("scene_changed", Callable(self, "_on_scene_changed_compat")):
			tree.connect("scene_changed", Callable(self, "_on_scene_changed_compat"))

func get_current_step() -> String:
	return ORDERED_STEPS[current_step_index]

func get_next_step() -> String:
	if current_step_index >= ORDERED_STEPS.size() - 1:
		return ORDERED_STEPS[current_step_index]
	return ORDERED_STEPS[current_step_index + 1]

func complete_step(step_id: String) -> void:
	if not completed_steps.has(step_id):
		completed_steps.append(step_id)
	while current_step_index < ORDERED_STEPS.size() - 1 and completed_steps.has(get_current_step()):
		current_step_index += 1
	_update_time_of_day_from_step()

func can_enter(step_id: String) -> bool:
	if not strict_mode:
		return true
	if step_id == get_current_step():
		return true
	if allow_revisit_completed and completed_steps.has(step_id):
		return true
	return false

func objective_text() -> String:
	var label := get_current_step().replace("_", " ")
	return "Current Objective: %s (%s)" % [label.capitalize(), time_of_day]

func reset_to_morning() -> void:
	current_step_index = 0
	completed_steps = PackedStringArray()
	show_begin_quiz = false
	_daily_once_flags.clear()
	_update_time_of_day_from_step()

func consume_daily_once(flag_id: String) -> bool:
	if flag_id == "":
		return false
	if _daily_once_flags.has(flag_id):
		return false
	_daily_once_flags[flag_id] = true
	return true

func consume_begin_quiz_flag() -> bool:
	if not show_begin_quiz:
		return false
	show_begin_quiz = false
	return true

func catch_up_to(target_step_id: String) -> void:
	var target_idx: int = ORDERED_STEPS.find(target_step_id)
	if target_idx < 0:
		return
	var safety := 0
	while current_step_index < target_idx and safety < ORDERED_STEPS.size():
		var cur: String = get_current_step()
		complete_step(cur)
		safety += 1

func get_time_of_day() -> String:
	return time_of_day

func note_next_location_from_scene_path(path: String) -> void:
	_pending_location_label = _friendly_location_name(path)

func _update_time_of_day_from_step() -> void:
	time_of_day = str(STEP_TIME_OF_DAY.get(get_current_step(), "Daytime"))

func _friendly_location_name(scene_path: String) -> String:
	var p := scene_path.get_file().get_basename().to_lower()
	if LOCATION_NAME_OVERRIDES.has(p):
		return str(LOCATION_NAME_OVERRIDES[p])
	var clean := p.replace("_", " ").strip_edges()
	return clean.capitalize()

func _on_current_scene_changed(_scene: Node) -> void:
	var label := _pending_location_label
	_pending_location_label = ""
	if label == "":
		var cur := get_tree().current_scene
		if cur != null and "scene_file_path" in cur:
			label = _friendly_location_name(str(cur.scene_file_path))
	if label == "":
		return
	call_deferred("_show_location_popup", label)

func _on_scene_changed_compat() -> void:
	_on_current_scene_changed(null)

func _show_location_popup(label: String) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 95
	tree.current_scene.add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 420
	panel.offset_right = -420
	panel.offset_top = 24
	panel.offset_bottom = 88
	root.add_child(panel)
	var label_ui := Label.new()
	label_ui.text = label + "  •  " + time_of_day
	label_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_ui.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_ui.add_theme_font_size_override("font_size", 28)
	panel.add_child(label_ui)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_interval(1.65)
	tw.tween_property(panel, "modulate:a", 0.0, 0.28)
	await tw.finished
	if is_instance_valid(layer):
		layer.queue_free()
