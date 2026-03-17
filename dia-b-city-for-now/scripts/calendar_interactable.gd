extends Node3D

@export var schedule_ui_path: NodePath

var schedule_ui: CanvasLayer = null

func _resolve_schedule_ui() -> CanvasLayer:
	if schedule_ui != null:
		return schedule_ui
	if schedule_ui_path != NodePath(""):
		schedule_ui = get_node_or_null(schedule_ui_path) as CanvasLayer
	if schedule_ui == null:
		schedule_ui = get_parent().get_node_or_null("ScheduleUI") as CanvasLayer
	return schedule_ui

func interact(player: Node) -> void:
	var ui := _resolve_schedule_ui()
	if ui == null:
		return
	if ui.has_method("show_panel"):
		ui.show_panel(player)
