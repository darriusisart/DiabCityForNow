extends Control


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
func _ready() -> void:
	choose_random_prompt()
	
	
func choose_random_prompt() -> void:
	var random_prompt: String = prompts.pick_random()
	prompt_text.text = random_prompt
