extends Control

@onready var journal_panel = $JournalPanel
@onready var journal_tab = $JournalTab

@export var slide_time := 0.35
@export var tab_y := 40.0

var is_open := false
var tween: Tween

func _ready():
	await get_tree().process_frame

	size = get_viewport_rect().size
	journal_panel.size = size

	close_journal_instant()

func _process(_delta):
	if Input.is_action_just_pressed("open_journal"):
		toggle_journal()

func toggle_journal():
	if is_open:
		close_journal()
	else:
		open_journal()

func open_journal():
	is_open = true

	_slide_to(
		Vector2.ZERO,
		Vector2(size.x + 20, tab_y)
	)
	
func close_journal():
	is_open = false

	_slide_to(
		Vector2(-journal_panel.size.x, 0),
		Vector2(0, tab_y)
	)
	
func close_journal_instant():
	is_open = false
	journal_panel.position = Vector2(-journal_panel.size.x, 0)
	journal_tab.position = Vector2(0, tab_y)

func _slide_to(panel_target: Vector2, tab_target: Vector2):
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(journal_panel, "position", panel_target, slide_time)
	tween.tween_property(journal_tab, "position", tab_target, slide_time)
