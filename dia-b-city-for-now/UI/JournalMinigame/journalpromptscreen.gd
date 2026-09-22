extends Control

@onready var exit_button: Button = $UI/ExitButton

# Called when the node enters the scene tree for the first time.
@onready var prompt_text: Label = $JournalCenter/JournalPage/PromptText

var prompts: Array[String] = [
	"What was something that happened today that made you happy?",
	"Who is a person that you look up to? Why?",
	"What is one good choice that you made today?",
	"What is a song that cheers you up?",
	"What do you want to be when you grow up?",
	"Describe a time that you laughed so hard. What was going on?",
	"Describe a time that you helped someone out. How did it make you feel afterwards?",
	"What is a superpower that you want? How would you use your superpower?",
	"If you could talk to your pet, what would you tell them?",
	"Describe a time that you made a mistake. How did you fix it?",
	"What is your favorite thing about yourself?",
	"What is your favorite subject in school? Why is it your favorite?",
	"Write down something that you want to accomplish tomorrow in real life.",
	"If you could go anywhere in the world, where would you go?",
	"What is something that you want to do one day?",
	"Who is your best friend?",
	"If you could talk to your past self, what would you tell them?",
	"What is your favorite thing to do outside?",
	"What is something that you are good at?",
    "Think about a time when you hurt someone's feelings. How did you make it better afterwards?"
]
var normal_scale := Vector2(1.0, 1.0)
var hover_scale := Vector2(1.15, 1.15)
var pressed_scale := Vector2(1.08, 1.08)

var scale_tween: Tween

func _ready() -> void:
	choose_random_prompt()
	
	exit_button.pressed.connect(_on_exit_button_pressed)

	exit_button.mouse_entered.connect(_on_exit_button_mouse_entered)
	exit_button.mouse_exited.connect(_on_exit_button_mouse_exited)
	exit_button.button_down.connect(_on_exit_button_button_down)
	exit_button.button_up.connect(_on_exit_button_button_up)

	exit_button.pivot_offset = exit_button.size / 2.0
	
	
func choose_random_prompt() -> void:
	var random_prompt: String = prompts.pick_random()
	prompt_text.text = random_prompt
	
func _on_exit_button_mouse_entered():
	_scale_button(hover_scale)


func _on_exit_button_mouse_exited():
	_scale_button(normal_scale)


func _on_exit_button_button_down():
	_scale_button(pressed_scale)


func _on_exit_button_button_up():
	_scale_button(hover_scale)


func _scale_button(new_scale: Vector2):
	if scale_tween:
		scale_tween.kill()

	scale_tween = create_tween()
	scale_tween.tween_property(
		exit_button,
		"scale",
		new_scale,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_exit_button_pressed():
	print("EXIT BUTTON PRESSED")
	SceneManager.return_to_previous_scene()
