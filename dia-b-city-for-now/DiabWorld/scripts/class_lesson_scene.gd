extends Node2D

@export var lesson_title := "Class Lesson"
@export var teacher_name := "Teacher"
@export var lesson_chat: PackedStringArray = [
	"Today we are learning together.",
	"Listen to the chat and answer the question."
]
@export var randomized_convo_mode := true
@export var good_convo_topics: PackedStringArray = [
	"A classmate shares a quick gardening tip: compost + water + sunlight helps plants stay healthy.",
	"The teacher explains how reading ingredient labels can help you pick foods with less added sugar.",
	"A student suggests a short movement break between study blocks to help focus and energy.",
	"The class compares easy healthy snack ideas for lunch, like fruit, yogurt, and nuts.",
	"Someone asks how sleep and hydration affect learning, and the class builds a simple daily plan."
]
@export var distraction_convo_topics: PackedStringArray = [
	"Someone starts side-talk about random drama and focus drops.",
	"A loud interruption derails the room into distraction news mode.",
	"The class gets pulled off-topic by chatter in the back."
]
@export_multiline var lesson_question := "What did we just learn?"
@export var answer_choices: PackedStringArray = ["Choice A", "Choice B", "Choice C"]
@export_range(0, 10, 1) var correct_choice_index := 0
@export var reward_points := 5
@export_file("*.tscn") var back_scene_path := "res://DiabWorld/scenes/Recess_World.tscn"
@export_file("*.tscn") var next_scene_path := ""
@export var reward_pillar := "social"
@export var completion_step_id := ""
@export var reveal_on_quiz_complete_path: NodePath
## If true, after the last chat line the lesson goes straight to revealing [member reveal_on_quiz_complete_path] (no multiple-choice quiz).
@export var skip_lesson_quiz := false

@onready var title_label: Label = $CanvasLayer/Control/TopPanel/MarginContainer/VBoxContainer/Title
@onready var points_label: Label = $CanvasLayer/Control/TopPanel/MarginContainer/VBoxContainer/Points
@onready var chat_name_label: Label = $CanvasLayer/Control/BottomPanel/MarginContainer/VBoxContainer/TeacherName
@onready var chat_body_label: RichTextLabel = $CanvasLayer/Control/BottomPanel/MarginContainer/VBoxContainer/ChatBody
@onready var continue_button: Button = $CanvasLayer/Control/BottomPanel/MarginContainer/VBoxContainer/ContinueButton
@onready var question_panel: PanelContainer = $CanvasLayer/Control/QuestionPanel
@onready var question_label: Label = $CanvasLayer/Control/QuestionPanel/MarginContainer/VBoxContainer/Question
@onready var answers_box: VBoxContainer = $CanvasLayer/Control/QuestionPanel/MarginContainer/VBoxContainer/Answers
@onready var feedback_label: Label = $CanvasLayer/Control/QuestionPanel/MarginContainer/VBoxContainer/Feedback
@onready var back_button: Button = $CanvasLayer/Control/QuestionPanel/MarginContainer/VBoxContainer/BackButton
@onready var bottom_panel: PanelContainer = $CanvasLayer/Control/BottomPanel

var _chat_index := 0
var _answered := false
var _convo_is_good := true
## Set in randomized mode: "teacher" | "student" | "distracted"
var _lesson_style := "teacher"

func _ready() -> void:
	_build_randomized_convo_if_needed()
	title_label.text = lesson_title
	chat_name_label.text = teacher_name
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_apply_large_ui_text()
	_style_convo_ui()
	_setup_question()
	_show_chat_line()
	_update_points_label()

func _apply_large_ui_text() -> void:
	const TITLE_SZ := 48
	const SUB_SZ := 30
	const TEACHER_SZ := 34
	const CHAT_SZ := 30
	const BTN_SZ := 30
	const QUESTION_SZ := 32
	const FEEDBACK_SZ := 28
	title_label.add_theme_font_size_override("font_size", TITLE_SZ)
	points_label.add_theme_font_size_override("font_size", SUB_SZ)
	chat_name_label.add_theme_font_size_override("font_size", TEACHER_SZ)
	chat_body_label.add_theme_font_size_override("normal_font_size", CHAT_SZ)
	continue_button.add_theme_font_size_override("font_size", BTN_SZ)
	continue_button.custom_minimum_size = Vector2(0, 52)
	question_label.add_theme_font_size_override("font_size", QUESTION_SZ)
	feedback_label.add_theme_font_size_override("font_size", FEEDBACK_SZ)
	back_button.add_theme_font_size_override("font_size", BTN_SZ)
	back_button.custom_minimum_size = Vector2(0, 52)

func _style_convo_ui() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.08, 0.13, 0.24, 0.92)
	top_style.set_corner_radius_all(12)
	title_label.get_parent().get_parent().add_theme_stylebox_override("panel", top_style)

	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.06, 0.07, 0.10, 0.92)
	bottom_style.set_corner_radius_all(14)
	bottom_panel.add_theme_stylebox_override("panel", bottom_style)

	var tag := "Class"
	if randomized_convo_mode:
		match _lesson_style:
			"teacher":
				tag = "Teacher-led"
			"student":
				tag = "Student topic"
			_:
				tag = "Distracted Class"
	else:
		tag = "Attentive Class" if _convo_is_good else "Distracted Class"

	chat_name_label.text = "[%s] %s" % [tag, teacher_name]
	if _lesson_style == "distracted" or (not randomized_convo_mode and not _convo_is_good):
		chat_name_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.48))
	elif _lesson_style == "student":
		chat_name_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	else:
		chat_name_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.66))

func _build_randomized_convo_if_needed() -> void:
	if not randomized_convo_mode:
		return
	var roll := randf()
	if roll < 0.38:
		_lesson_style = "teacher"
	elif roll < 0.72:
		_lesson_style = "student"
	else:
		_lesson_style = "distracted"

	_convo_is_good = _lesson_style != "distracted"
	lesson_chat = PackedStringArray()

	if _lesson_style == "distracted":
		var source_bad := distraction_convo_topics
		if source_bad.is_empty():
			return
		var picked_idx := randi() % source_bad.size()
		lesson_chat.append(source_bad[picked_idx])
		lesson_chat.append("Side chatter spreads; the lesson thread frays.")
		lesson_chat.append("Focus drops and key points get missed.")
		lesson_question = "What hurt the class learning here?"
		answer_choices = PackedStringArray(["Careful note-taking", "Thoughtful questions", "Off-topic distraction"])
		correct_choice_index = 2
		lesson_title = "Class Conversation"
		teacher_name = "Class Feed"
		return

	if good_convo_topics.is_empty():
		return
	var picked_idx := randi() % good_convo_topics.size()
	var topic_line := str(good_convo_topics[picked_idx])
	if _lesson_style == "teacher":
		lesson_chat.append("%s leads: %s" % [teacher_name, topic_line])
		lesson_chat.append("The class follows along and adds quick examples.")
		lesson_chat.append("You take notes and connect the idea to your day.")
	elif _lesson_style == "student":
		lesson_chat.append("A student raises a hand and brings up: %s" % topic_line)
		lesson_chat.append("%s steers the room back on track without shutting people down." % teacher_name)
		lesson_chat.append("The class turns it into a short, useful discussion.")
	_apply_good_topic_quiz(picked_idx)
	lesson_title = "Class Conversation"
	if _lesson_style == "student":
		teacher_name = "Class + " + teacher_name

func _apply_good_topic_quiz(topic_idx: int) -> void:
	match topic_idx:
		0:
			lesson_question = "For plant growth, which combo is most important?"
			answer_choices = PackedStringArray(["Compost, water, and sunlight", "Candy, soda, and screen time", "Only extra fertilizer"])
			correct_choice_index = 0
		1:
			lesson_question = "When checking a snack label, what is a healthier sign?"
			answer_choices = PackedStringArray(["Lower added sugar and simpler ingredients", "More artificial colors", "Sugar listed first"])
			correct_choice_index = 0
		2:
			lesson_question = "Why can short movement breaks help during study?"
			answer_choices = PackedStringArray(["They support focus and steady energy", "They always reduce learning", "They only help before bed"])
			correct_choice_index = 0
		3:
			lesson_question = "Which lunch option is closest to the class healthy-snack idea?"
			answer_choices = PackedStringArray(["Fruit, yogurt, and nuts", "Soda and candy", "Only chips"])
			correct_choice_index = 0
		_:
			lesson_question = "What daily habits were linked to stronger learning?"
			answer_choices = PackedStringArray(["Sleep and hydration", "Skipping meals and sleep", "No movement at all"])
			correct_choice_index = 0

func _setup_question() -> void:
	question_label.text = lesson_question
	feedback_label.text = ""
	question_panel.visible = false
	for child in answers_box.get_children():
		child.queue_free()
	if skip_lesson_quiz:
		return
	for i in answer_choices.size():
		var answer_button := Button.new()
		answer_button.text = answer_choices[i]
		answer_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		answer_button.custom_minimum_size = Vector2(0, 56)
		answer_button.add_theme_font_size_override("font_size", 28)
		answer_button.pressed.connect(_on_answer_pressed.bind(i))
		answers_box.add_child(answer_button)

func _show_chat_line() -> void:
	if lesson_chat.is_empty():
		chat_body_label.text = "No lesson text configured."
		return
	chat_body_label.text = lesson_chat[_chat_index]

func _on_continue_pressed() -> void:
	if lesson_chat.is_empty():
		_open_question()
		return
	if _chat_index < lesson_chat.size() - 1:
		_chat_index += 1
		_show_chat_line()
	else:
		if skip_lesson_quiz:
			await _finish_chat_without_quiz()
		else:
			_open_question()

func _finish_chat_without_quiz() -> void:
	await get_tree().create_timer(0.18).timeout
	_reveal_completion_node()
	bottom_panel.visible = false
	continue_button.visible = false

func _open_question() -> void:
	question_panel.visible = true
	continue_button.disabled = true

func _on_answer_pressed(choice_index: int) -> void:
	if _answered:
		return
	_answered = true
	var got_it_right := choice_index == correct_choice_index
	if got_it_right:
		if Data != null:
			Data.add_class_points(reward_points)
		var pl: Node = Data.pillars()
		if pl != null and pl.has_method("add_xp"):
			pl.add_xp(reward_pillar, reward_points, "lesson_quiz")
			if _convo_is_good:
				pl.add_xp("social", 3, "class_good_conversation")
		feedback_label.text = "Correct! +" + str(reward_points) + " points."
		feedback_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	else:
		var pl2: Node = Data.pillars()
		if pl2 != null and pl2.has_method("add_xp") and not _convo_is_good:
			pl2.add_xp("sleep", 1, "class_distraction_fatigue")
		feedback_label.text = "Not quite. Try again next class."
		feedback_label.modulate = Color(1.0, 0.6, 0.6, 1.0)

	for child in answers_box.get_children():
		if child is Button:
			child.disabled = true
	_update_points_label()
	_reveal_completion_node()
	back_button.visible = true

func _update_points_label() -> void:
	var points := 0
	if Data != null:
		points = Data.class_points
	points_label.text = "Knowledge Points: %d" % points

func _on_back_pressed() -> void:
	var df: Node = Data.day_flow()
	if completion_step_id != "" and df != null and df.has_method("complete_step"):
		df.complete_step(completion_step_id)
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
		return
	get_tree().change_scene_to_file(back_scene_path)

func _reveal_completion_node() -> void:
	if reveal_on_quiz_complete_path == NodePath(""):
		return
	var node_to_reveal := get_node_or_null(reveal_on_quiz_complete_path)
	if node_to_reveal == null:
		return
	if "visible" in node_to_reveal:
		node_to_reveal.visible = true
