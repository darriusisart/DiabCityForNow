extends CanvasLayer

@export var player_path: NodePath

@onready var panel: PanelContainer = $Panel
@onready var learned_body: Label = %LearnedBody
var _current_player: Node = null
var _ignore_interact_until_release := false
var _return_to_pause_menu: Node = null
var _base_canvas_layer := 0

func _ready() -> void:
	_base_canvas_layer = layer
	hide_panel()
	_refresh_learning_notes()

func show_panel(player: Node) -> void:
	_bring_to_front_ui()
	_current_player = player
	panel.visible = true
	_refresh_learning_notes()
	_ignore_interact_until_release = true
	_return_to_pause_menu = null
	if _current_player != null and _current_player.has_method("set_ui_locked"):
		_current_player.set_ui_locked(true)

func show_panel_from_pause(player: Node, pause_menu: Node) -> void:
	_bring_to_front_ui()
	_current_player = player
	panel.visible = true
	_refresh_learning_notes()
	_ignore_interact_until_release = true
	_return_to_pause_menu = pause_menu
	if _current_player != null and _current_player.has_method("set_ui_locked"):
		_current_player.set_ui_locked(true)

func hide_panel() -> void:
	layer = _base_canvas_layer
	panel.visible = false
	_ignore_interact_until_release = false
	if _return_to_pause_menu != null and _return_to_pause_menu.has_method("show_menu"):
		_return_to_pause_menu.show_menu(_current_player)
		_return_to_pause_menu = null
		_current_player = null
		return
	if _current_player != null and _current_player.has_method("set_ui_locked"):
		_current_player.set_ui_locked(false)
	_return_to_pause_menu = null
	_current_player = null

func _process(_delta: float) -> void:
	if not panel.visible:
		return
	if _ignore_interact_until_release:
		if Input.is_action_pressed("interact"):
			return
		_ignore_interact_until_release = false
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
		hide_panel()

func _bring_to_front_ui() -> void:
	layer = maxi(_base_canvas_layer, 130)

func refresh_learning_notes() -> void:
	_refresh_learning_notes()

func _refresh_learning_notes() -> void:
	if learned_body == null:
		return
	var lines: Array[String] = []
	if Data != null and Data.has_method("get_learning_notes"):
		lines = Data.get_learning_notes()
	if lines.is_empty():
		learned_body.text = "- No notes yet. Talk with students and attend class."
		return
	var rendered := ""
	for line in lines:
		rendered += "- %s\n" % line
	learned_body.text = rendered.strip_edges()
