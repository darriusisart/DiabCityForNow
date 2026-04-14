extends Node3D
signal dialog_closed(choice: String)

@export var display_name := "Classmate"
@export var chat_pillar := "social"
@export var chat_xp := 6
@export var race_exercise_xp := 8
@export var race_social_xp := 3
@export var convo_topics: PackedStringArray = [
	"how to start a windowsill herb garden with mint and basil",
	"an easy lunch swap: water + fruit instead of soda + candy",
	"one PE warmup move that helps prevent ankle and knee strain",
	"a quick label-reading trick: if sugar is in the top ingredients, pick another option",
	"an after-school activity idea that boosts mood and sleep quality"
]

func interact(player: Node) -> void:
	if player.has_method("set_ui_locked"):
		player.set_ui_locked(true)
	var layer := CanvasLayer.new()
	layer.layer = 110
	get_tree().root.add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200.0
	panel.offset_top = -120.0
	panel.offset_right = 200.0
	panel.offset_bottom = 120.0
	layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "Chat, race, or close."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	var choice_made := ""
	var btn_chat := Button.new()
	btn_chat.text = "Chat"
	var btn_race := Button.new()
	btn_race.text = "Race"
	var btn_close := Button.new()
	btn_close.text = "Close"
	row.add_child(btn_chat)
	row.add_child(btn_race)
	row.add_child(btn_close)
	var end_dialog := func(choice: String) -> void:
		choice_made = choice
		emit_signal("dialog_closed", choice)
		if is_instance_valid(layer):
			layer.queue_free()
	btn_chat.pressed.connect(end_dialog.bind("chat"))
	btn_race.pressed.connect(end_dialog.bind("race"))
	btn_close.pressed.connect(end_dialog.bind(""))
	await dialog_closed
	if player.has_method("set_ui_locked"):
		player.set_ui_locked(false)
	if choice_made == "chat":
		var pl: Node = Data.pillars()
		if pl != null and pl.has_method("add_xp"):
			pl.add_xp(chat_pillar, chat_xp, "recess_classmate_chat")
			pl.add_xp("social", 1, "recess_chat_topic")
		print(_chat_line())
	elif choice_made == "race":
		await get_tree().create_timer(1.2).timeout
		var won: bool = randf() < 0.55
		var pl2: Node = Data.pillars()
		if pl2 != null and pl2.has_method("add_xp"):
			pl2.add_xp("exercise", race_exercise_xp if won else 3, "recess_race")
			pl2.add_xp("social", race_social_xp, "recess_friendly_competition")

func _chat_line() -> String:
	if convo_topics.is_empty():
		return "You had a short but nice recess chat."
	var topic := convo_topics[randi() % convo_topics.size()]
	return "You chat about %s." % topic
