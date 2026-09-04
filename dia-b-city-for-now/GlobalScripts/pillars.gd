extends Node

const PILLAR_IDS := ["wellbeing", "social", "exercise", "nutrition", "sleep"]
const XP_PER_LEVEL := 200
const STAT_IDS := ["total_xp_earned", "items_carted", "nutrition_earned", "foods_dropped", "mini_games_played"]

signal stats_changed

var pillars := {
	"wellbeing": {"xp": 0, "level": 1, "today_delta": 0, "milestones": PackedStringArray()},
	"social": {"xp": 0, "level": 1, "today_delta": 0, "milestones": PackedStringArray()},
	"exercise": {"xp": 0, "level": 1, "today_delta": 0, "milestones": PackedStringArray()},
	"nutrition": {"xp": 0, "level": 1, "today_delta": 0, "milestones": PackedStringArray()},
	"sleep": {"xp": 0, "level": 1, "today_delta": 0, "milestones": PackedStringArray()}
}
var stats := {
	"total_xp_earned": 0,
	"items_carted": 0,
	"nutrition_earned": 0,
	"foods_dropped": 0,
	"mini_games_played": 0
}

func reset_today_delta() -> void:
	for pillar_id in PILLAR_IDS:
		pillars[pillar_id]["today_delta"] = 0

func add_xp(pillar_id: String, amount: int, source: String = "") -> void:
	if not pillars.has(pillar_id):
		return
	var clamped_amount: int = max(amount, 0)
	pillars[pillar_id]["xp"] += clamped_amount
	pillars[pillar_id]["today_delta"] += clamped_amount
	stats["total_xp_earned"] += clamped_amount
	_update_level(pillar_id)
	_try_unlock_milestone(pillar_id, source)
	_show_xp_popup(pillar_id, clamped_amount)
	emit_signal("stats_changed")

func add_stat(stat_id: String, amount: int) -> void:
	if not stats.has(stat_id):
		return
	stats[stat_id] += max(amount, 0)
	emit_signal("stats_changed")

func get_stat(stat_id: String) -> int:
	if not stats.has(stat_id):
		return 0
	return int(stats[stat_id])

func get_stats() -> Dictionary:
	return stats.duplicate(true)

func get_pillar(pillar_id: String) -> Dictionary:
	if not pillars.has(pillar_id):
		return {}
	return pillars[pillar_id]

func get_xp_to_next_level(pillar_id: String) -> int:
	if not pillars.has(pillar_id):
		return XP_PER_LEVEL
	var xp: int = pillars[pillar_id]["xp"]
	return XP_PER_LEVEL - (xp % XP_PER_LEVEL)

func get_xp_per_level() -> int:
	return XP_PER_LEVEL

func _update_level(pillar_id: String) -> void:
	var xp: int = pillars[pillar_id]["xp"]
	pillars[pillar_id]["level"] = 1 + int(xp / XP_PER_LEVEL)

func _try_unlock_milestone(pillar_id: String, source: String) -> void:
	var milestone_key := ""
	var level: int = pillars[pillar_id]["level"]
	if level >= 2:
		milestone_key = "level_2"
	if source != "":
		milestone_key = source
	if milestone_key == "":
		return

	var unlocked: PackedStringArray = pillars[pillar_id]["milestones"]
	if unlocked.has(milestone_key):
		return
	unlocked.append(milestone_key)
	pillars[pillar_id]["milestones"] = unlocked

func _show_xp_popup(pillar_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 190
	tree.current_scene.add_child(layer)
	var label := Label.new()
	label.text = "+%d %s XP" % [amount, _pillar_label(pillar_id)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.modulate = Color(1.0, 0.95, 0.55, 0.0)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -340
	label.offset_top = -40
	label.offset_right = 340
	label.offset_bottom = 40
	layer.add_child(label)
	var tw := label.create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.12)
	tw.tween_property(label, "position:y", label.position.y - 24.0, 0.65)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	await tw.finished
	if is_instance_valid(layer):
		layer.queue_free()

func _pillar_label(pillar_id: String) -> String:
	match pillar_id:
		"wellbeing":
			return "Wellbeing"
		"social":
			return "Social"
		"exercise":
			return "Exercise"
		"nutrition":
			return "Nutrition"
		"sleep":
			return "Sleep"
		_:
			return "Stat"
