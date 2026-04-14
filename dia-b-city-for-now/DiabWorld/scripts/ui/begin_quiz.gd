extends CanvasLayer

signal quiz_finished

const QUESTIONS := [
	{"question": "Which sounds most like you?", "answers": ["I like to move", "I like people time", "I like healthy choices"], "pillar": ["exercise", "social", "nutrition"]},
	{"question": "What helps you reset best?", "answers": ["Stretching", "Talking to someone", "Hydrating/snack"], "pillar": ["wellbeing", "social", "nutrition"]},
	{"question": "When do you usually feel most rested?", "answers": ["After a full night's sleep", "After quiet downtime", "After being with people I like"], "pillar": ["sleep", "wellbeing", "social"]},
	{"question": "What boosts your energy the most?", "answers": ["A balanced meal or snack", "Moving my body", "A good nap or bedtime"], "pillar": ["nutrition", "exercise", "sleep"]},
	{"question": "How do you prefer to recharge?", "answers": ["Solo time to unwind", "Chatting or laughing with someone", "Light movement or stretching"], "pillar": ["wellbeing", "social", "exercise"]},
	{"question": "What's your first move on a busy day?", "answers": ["Drink water / grab fuel", "Check in with a friend", "Take a few calm breaths"], "pillar": ["nutrition", "social", "wellbeing"]},
]

@onready var panel: PanelContainer = $Panel
@onready var question_label: Label = $Panel/Margin/VBox/Question
@onready var answers_box: VBoxContainer = $Panel/Margin/VBox/Answers

var _index := 0
var _player: Node = null

func start_standalone() -> void:
	_player = null
	panel.visible = true
	_render_question()

func start(player: Node) -> void:
	_player = player
	panel.visible = true
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(true)
	_render_question()

func _render_question() -> void:
	for child in answers_box.get_children():
		child.queue_free()

	var data: Dictionary = QUESTIONS[_index]
	question_label.text = data["question"]
	var answers: Array = data["answers"]
	for i in answers.size():
		var button := Button.new()
		button.text = str(answers[i])
		button.pressed.connect(_on_answer_pressed.bind(i))
		answers_box.add_child(button)

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

func _finish_quiz() -> void:
	panel.visible = false
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(false)
	var df: Node = Data.day_flow()
	if df != null and df.has_method("complete_step"):
		df.complete_step("wake_up")
	emit_signal("quiz_finished")
