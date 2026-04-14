extends CanvasLayer

@export var player_path: NodePath

@onready var panel: PanelContainer = $Panel
var _current_player: Node = null
var _ignore_interact_until_release := false
var _return_to_pause_menu: Node = null

func _ready() -> void:
	hide_panel()

func show_panel(player: Node) -> void:
	_current_player = player
	panel.visible = true
	_ignore_interact_until_release = true
	_return_to_pause_menu = null
	if _current_player != null and _current_player.has_method("set_ui_locked"):
		_current_player.set_ui_locked(true)

func show_panel_from_pause(player: Node, pause_menu: Node) -> void:
	_current_player = player
	panel.visible = true
	_ignore_interact_until_release = true
	_return_to_pause_menu = pause_menu
	if _current_player != null and _current_player.has_method("set_ui_locked"):
		_current_player.set_ui_locked(true)

func hide_panel() -> void:
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
