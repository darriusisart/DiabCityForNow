extends CanvasLayer

signal quiz_finished

const QUESTIONS := [
	{"question": "Which sounds most like you?", "answers": ["I like to move", "I like people time", "I like healthy choices"], "pillar": ["exercise", "social", "nutrition"]},
	{"question": "What helps you reset best?", "answers": ["Stretching", "Talking to someone", "Hydrating/snack"], "pillar": ["wellbeing", "social", "nutrition"]},
	{"question": "When do you usually feel most rested?", "answers": ["After a full night's sleep", "After quiet downtime", "After being with people I like"], "pillar": ["sleep", "wellbeing", "social"]},
	{"question": "What boosts your energy the most?", "answers": ["A balanced meal or snack", "Moving my body", "A good nap or bedtime"], "pillar": ["nutrition", "exercise", "sleep"]},
	{"question": "How do you prefer to recharge?", "answers": ["Solo time to unwind", "Chatting or laughing with someone", "Light movement or stretching"], "pillar": ["wellbeing", "social", "exercise"]},
	{"question": "What's your first move on a busy day?", "answers": ["Drink water / grab fuel", "Check in with a friend", "Take a few calm breaths"], "pillar": ["nutrition", "social", "wellbeing"]},
	{"question": "What is your username?", "type": "username"}
]

@onready var panel: PanelContainer = $QuizOverlay/Panel
@onready var title_label: Label = $QuizOverlay/Panel/Margin/VBox/Title
@onready var question_label: Label = $QuizOverlay/Panel/Margin/VBox/Question
@onready var answers_box: VBoxContainer = $QuizOverlay/Panel/Margin/VBox/Answers

var _index := 0
var _player: Node = null

const _POPPINS: Font = preload("res://Font/Poppins/Poppins-Regular.ttf")
const INTRO_SPINE_CUSTOMIZE := preload("res://DiabWorld/scenes/ui/intro_spine_customize.tscn")

func _style_stat_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _POPPINS)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 1.0))

## Same math as pause_menu.gd _set_label / _refresh_stats.
func _apply_pillar_label_and_bar(label: Label, bar: ProgressBar, title: String, pillar: Dictionary) -> void:
	var level := int(pillar.get("level", 1))
	var xp := int(pillar.get("xp", 0))
	var delta := int(pillar.get("today_delta", 0))
	var xp_per_level := 200
	var pl_ref: Node = Data.pillars()
	if pl_ref != null and pl_ref.has_method("get_xp_per_level"):
		xp_per_level = int(pl_ref.get_xp_per_level())
	var in_level_xp := xp % xp_per_level
	var filled_points := int(floor((float(in_level_xp) / float(xp_per_level)) * 5.0))
	filled_points = clampi(filled_points, 0, 5)
	label.text = "%s  Lv.%d  XP:%d  Today:+%d  Progress:%d/5" % [title, level, xp, delta, filled_points]
	if bar != null:
		bar.value = float(filled_points)

func _add_pillar_stat_rows(vbox: VBoxContainer) -> void:
	var pl: Node = Data.pillars()
	if pl == null or not pl.has_method("get_pillar"):
		return
	var pairs: Array = [["wellbeing", "Wellbeing"], ["social", "Social"], ["exercise", "Exercise"], ["nutrition", "Nutrition"], ["sleep", "Sleep"]]
	for pair in pairs:
		var pillar_id: String = str(pair[0])
		var disp: String = str(pair[1])
		var pillar: Dictionary = pl.get_pillar(pillar_id)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_stat_label(lbl)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 18)
		bar.max_value = 5.0
		bar.step = 1.0
		bar.show_percentage = false
		_apply_pillar_label_and_bar(lbl, bar, disp, pillar)
		vbox.add_child(lbl)
		vbox.add_child(bar)

func _show_pillar_summary() -> void:
	for child in answers_box.get_children():
		answers_box.remove_child(child)
		child.queue_free()
	var username := String(Data.player_username).strip_edges()
	if username == "":
		username = "Student"
	title_label.text = "Your pillars (%s)" % username
	question_label.text = "Here's your progress"
	var df: Node = Data.day_flow()
	if df != null and df.has_method("objective_text"):
		var obj := Label.new()
		obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_stat_label(obj)
		obj.add_theme_font_size_override("font_size", 20)
		obj.text = df.objective_text()
		answers_box.add_child(obj)
	_add_pillar_stat_rows(answers_box)
	var pl2: Node = Data.pillars()
	if pl2 != null and pl2.has_method("get_stat"):
		var gs := Label.new()
		gs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_stat_label(gs)
		gs.add_theme_font_size_override("font_size", 16)
		gs.text = (
			"Totals  XP:+%d  Items:%d  Nutrition:%d  Dropped:%d  Mini-games:%d"
			% [
				pl2.get_stat("total_xp_earned"),
				pl2.get_stat("items_carted"),
				pl2.get_stat("nutrition_earned"),
				pl2.get_stat("foods_dropped"),
				pl2.get_stat("mini_games_played")
			]
		)
		answers_box.add_child(gs)
	var cont := _make_textured_answer_row("Continue")
	var btn: Button = cont.get_child(0) as Button
	btn.pressed.connect(_open_character_customization)
	answers_box.add_child(cont)

func _style_line_edit_like_question(le: LineEdit) -> void:
	le.add_theme_font_override("font", _POPPINS)
	le.add_theme_font_size_override("font_size", 20)
	le.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 1.0))
	le.add_theme_color_override("font_placeholder_color", Color(0.92, 0.94, 0.96, 0.55))

## Default project Button = textured bg (SHREYA_tHEME). Caption is a Label on top so text
## stays visible on the high CanvasLayer; clicks pass through to the Button underneath.
func _make_textured_answer_row(caption: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 58)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn := Button.new()
	var pt: Theme = ThemeDB.get_project_theme()
	if pt != null:
		btn.theme = pt
	btn.text = ""
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 0.0
	btn.offset_top = 0.0
	btn.offset_right = 0.0
	btn.offset_bottom = 0.0
	var cap := Label.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.set_anchors_preset(Control.PRESET_FULL_RECT)
	cap.offset_left = 12.0
	cap.offset_top = 6.0
	cap.offset_right = -12.0
	cap.offset_bottom = -6.0
	cap.add_theme_font_override("font", _POPPINS)
	cap.add_theme_font_size_override("font_size", 20)
	cap.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 1.0))
	holder.add_child(btn)
	holder.add_child(cap)
	return holder

func start_standalone() -> void:
	_player = null
	panel.visible = true
	title_label.text = "Start Day Quiz"
	_render_question()

func start(player: Node) -> void:
	_player = player
	panel.visible = true
	title_label.text = "Start Day Quiz"
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(true)
	_render_question()

func _render_question() -> void:
	for child in answers_box.get_children():
		answers_box.remove_child(child)
		child.queue_free()
	if _index < QUESTIONS.size():
		title_label.text = "Start Day Quiz"

	var data: Dictionary = QUESTIONS[_index]
	question_label.text = data["question"]
	if str(data.get("type", "")) == "username":
		var input := LineEdit.new()
		input.placeholder_text = "Enter username"
		input.max_length = 24
		input.text = String(Data.player_username)
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_line_edit_like_question(input)
		answers_box.add_child(input)
		var submit_row := _make_textured_answer_row("Continue")
		var submit: Button = submit_row.get_child(0) as Button
		submit.pressed.connect(func() -> void:
			_on_username_submitted(input.text)
		)
		answers_box.add_child(submit_row)
		input.grab_focus()
		return
	var answers: Array = data["answers"]
	for i in answers.size():
		var row := _make_textured_answer_row(str(answers[i]))
		var button: Button = row.get_child(0) as Button
		button.pressed.connect(_on_answer_pressed.bind(i))
		answers_box.add_child(row)

func _on_answer_pressed(answer_index: int) -> void:
	var data: Dictionary = QUESTIONS[_index]
	var pillar_key: String = data["pillar"][answer_index]
	var pl: Node = Data.pillars()
	if pl != null and pl.has_method("add_xp"):
		pl.add_xp(pillar_key, 25, "begin_quiz")
	_index += 1
	if _index >= QUESTIONS.size():
		_finish_quiz()
	else:
		_render_question()

func _on_username_submitted(raw_name: String) -> void:
	var cleaned := raw_name.strip_edges()
	if cleaned == "":
		cleaned = "Student"
	Data.player_username = cleaned
	_index += 1
	if _index >= QUESTIONS.size():
		_show_pillar_summary()
	else:
		_render_question()

func _open_character_customization() -> void:
	visible = false
	var layer: CanvasLayer = INTRO_SPINE_CUSTOMIZE.instantiate()
	layer.customization_finished.connect(_on_character_customization_finished, CONNECT_ONE_SHOT)
	var host: Node = get_parent()
	if host != null:
		host.add_child(layer)
	else:
		get_tree().current_scene.add_child(layer)

func _on_character_customization_finished() -> void:
	if _player != null and _player.has_method("refresh_spine_appearance"):
		_player.refresh_spine_appearance()
	else:
		for n in get_tree().get_nodes_in_group("player_avatar"):
			if n != null and n.has_method("refresh_spine_appearance"):
				n.refresh_spine_appearance()
				break
	_finish_quiz()

func _finish_quiz() -> void:
	panel.visible = false
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(false)
	var df: Node = Data.day_flow()
	if df != null and df.has_method("complete_step"):
		df.complete_step("wake_up")
	emit_signal("quiz_finished")
