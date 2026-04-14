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
	var df: Node = Data.day_flow()
	if df != null and df.has_method("complete_step"):
		df.complete_step("calendar")
	var pl: Node = Data.pillars()
	var grant_calendar_xp := true
	if df != null and df.has_method("consume_daily_once"):
		grant_calendar_xp = bool(df.consume_daily_once("calendar_check"))
	if grant_calendar_xp and pl != null and pl.has_method("add_xp"):
		pl.add_xp("wellbeing", 5, "calendar_check")
	if ui.has_method("show_panel"):
		ui.show_panel(player)
