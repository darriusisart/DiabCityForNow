extends Node3D

@export var player_path: NodePath = NodePath("player")
@export var interior_round_seconds := 30.0

var _mini_game_manager: Node2D = null
var _player: Node = null
var _active_aisle := ""
var _time_remaining := 0.0
var _round_over := false

@onready var status_label: Label = $StoreUI/PanelContainer/Label
@onready var timer_label: Label = $StoreUI/TimerLabel

func _ready() -> void:
	_player = get_node_or_null(player_path)
	_time_remaining = interior_round_seconds
	_update_timer_text()
	_setup_minigame_manager()

func _setup_minigame_manager() -> void:
	var manager_script := load("res://ConvienceStoreMiniGame/Scripts/mini_game_manager.gd")
	if manager_script == null:
		return
	_mini_game_manager = Node2D.new()
	_mini_game_manager.name = "MiniGameManager"
	_mini_game_manager.set_script(manager_script)
	add_child(_mini_game_manager)
	if _mini_game_manager.has_signal("mini_game_finished"):
		_mini_game_manager.connect("mini_game_finished", _on_mini_game_finished)

func _process(delta: float) -> void:
	if _round_over:
		return
	_time_remaining = maxf(0.0, _time_remaining - delta)
	_update_timer_text()
	if _time_remaining <= 0.0:
		_end_interior_round()

func interact_with_aisle(aisle_name: String, difficulty: String) -> void:
	if _round_over:
		return
	if _mini_game_manager == null:
		return
	if _mini_game_manager.get("active"):
		status_label.text = "Finish the current minigame first."
		return
	_active_aisle = aisle_name
	status_label.text = "Aisle %s challenge started..." % aisle_name
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(true)
	_mini_game_manager.call("start_random", difficulty, {})

func _on_mini_game_finished(success: bool) -> void:
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(false)
	var result := "success" if success else "failed"
	status_label.text = "Aisle %s %s. Move to another aisle and press E." % [_active_aisle, result]

func _update_timer_text() -> void:
	if timer_label == null:
		return
	var sec := int(ceil(_time_remaining))
	timer_label.text = "Store Time: %d:%02d" % [sec / 60, sec % 60]

func _end_interior_round() -> void:
	if _round_over:
		return
	_round_over = true
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(true)
	status_label.text = "Time is up!"
	var end_scr := load("res://ConvienceStoreMiniGame/Scripts/end_screen.gd")
	if end_scr == null:
		return
	var end_node := Node2D.new()
	end_node.name = "EndScreen"
	end_node.set_script(end_scr)
	add_child(end_node)
	end_node.call("show_results", [], 0, 0, 0, get_viewport().get_visible_rect().size)
