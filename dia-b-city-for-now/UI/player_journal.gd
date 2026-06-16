extends Control

@onready var journal_panel = $JournalPanel
@onready var journal_tab = $JournalTab

@onready var menu_button = $JournalPanel/NavBar/MenuButton
@onready var progress_button = $JournalPanel/NavBar/ProgressButton
@onready var map_button = $JournalPanel/NavBar/MapButton
@onready var clues_button = $JournalPanel/NavBar/CluesButton

@onready var menu_page = $JournalPanel/Pages/MenuPage
@onready var progress_page = $JournalPanel/Pages/ProgressPage
@onready var map_page = $JournalPanel/Pages/MapPage
@onready var clues_page = $JournalPanel/Pages/CluesPage

@export var slide_time := 0.35
@export var tab_y := 40.0

var is_open := false
var tween: Tween

func _ready():
	await get_tree().process_frame

	size = get_viewport_rect().size
	journal_panel.size = size

	menu_button.pressed.connect(func(): show_page("menu"))
	progress_button.pressed.connect(func(): show_page("progress"))
	map_button.pressed.connect(func(): show_page("map"))
	clues_button.pressed.connect(func(): show_page("clues"))

	show_page("menu")

	close_journal_instant()
	
	journal_tab.show()
	journal_tab.z_index = 10

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
	journal_tab.visible = true

	_slide_to(
		Vector2(-journal_panel.size.x, 0),
		Vector2(0, tab_y)
	)
	
func close_journal_instant():
	is_open = false
	journal_panel.position = Vector2(-journal_panel.size.x, 0)
	journal_tab.position = Vector2(0, tab_y)
	journal_tab.visible = true

func _slide_to(panel_target: Vector2, tab_target: Vector2):
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(journal_panel, "position", panel_target, slide_time)
	tween.tween_property(journal_tab, "position", tab_target, slide_time)

func show_page(page_name: String):
	menu_page.visible = page_name == "menu"
	progress_page.visible = page_name == "progress"
	map_page.visible = page_name == "map"
	clues_page.visible = page_name == "clues"
