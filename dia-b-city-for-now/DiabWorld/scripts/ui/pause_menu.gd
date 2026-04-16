extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var objective_label: Label = $Panel/Margin/VBox/Objective
@onready var wellbeing_label: Label = $Panel/Margin/VBox/Wellbeing
@onready var wellbeing_bar: ProgressBar = $Panel/Margin/VBox/WellbeingBar
@onready var social_label: Label = $Panel/Margin/VBox/Social
@onready var social_bar: ProgressBar = $Panel/Margin/VBox/SocialBar
@onready var exercise_label: Label = $Panel/Margin/VBox/Exercise
@onready var exercise_bar: ProgressBar = $Panel/Margin/VBox/ExerciseBar
@onready var nutrition_label: Label = $Panel/Margin/VBox/Nutrition
@onready var nutrition_bar: ProgressBar = $Panel/Margin/VBox/NutritionBar
@onready var sleep_label: Label = $Panel/Margin/VBox/Sleep
@onready var sleep_bar: ProgressBar = $Panel/Margin/VBox/SleepBar
@onready var global_stats_label: Label = $Panel/Margin/VBox/GlobalStats
@onready var close_button: Button = $Panel/Margin/VBox/Buttons/ResumeButton
@onready var notebook_button: Button = $Panel/Margin/VBox/Buttons/NotebookButton
@onready var inventory_button: Button = $Panel/Margin/VBox/Buttons/InventoryButton
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_list: ItemList = $InventoryPanel/Margin/VBox/InventoryList
@onready var eat_button: Button = $InventoryPanel/Margin/VBox/EatButton
@onready var eat_hint_label: Label = $InventoryPanel/Margin/VBox/EatHint
@onready var inventory_close_button: Button = $InventoryPanel/Margin/VBox/CloseInventoryButton

var _player: Node = null
var _inventory_keys: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	inventory_panel.visible = false
	_disable_keyboard_focus()
	close_button.pressed.connect(hide_menu)
	notebook_button.pressed.connect(_open_notebook)
	inventory_button.pressed.connect(_open_inventory)
	inventory_close_button.pressed.connect(_close_inventory)
	eat_button.pressed.connect(_eat_selected_inventory_item)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var ke := event as InputEventKey
	if not ke.pressed or ke.echo:
		return
	if ke.keycode != KEY_TAB:
		return
	var vp := get_viewport()
	if vp != null:
		var focus := vp.gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit:
			return
	if is_open():
		hide_menu()
	else:
		var p := _find_player_for_pause()
		if p != null:
			show_menu(p)
	get_viewport().set_input_as_handled()

func _find_player_for_pause() -> Node:
	var nodes := get_tree().get_nodes_in_group("player_avatar")
	if not nodes.is_empty():
		return nodes[0] as Node
	var scene := get_tree().current_scene
	if scene != null:
		var n := scene.get_node_or_null("Player")
		if n != null:
			return n
	return null

func _disable_keyboard_focus() -> void:
	for ctrl in [close_button, notebook_button, inventory_button, inventory_close_button, eat_button, inventory_list]:
		if ctrl != null:
			ctrl.focus_mode = Control.FOCUS_NONE

func show_menu(player: Node) -> void:
	_player = player
	panel.visible = true
	get_tree().paused = true
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(true)
	_refresh_stats()

func hide_menu() -> void:
	panel.visible = false
	inventory_panel.visible = false
	get_tree().paused = false
	if _player != null and _player.has_method("set_ui_locked"):
		_player.set_ui_locked(false)

func is_open() -> bool:
	return panel.visible or inventory_panel.visible

func _refresh_stats() -> void:
	var username := "Student"
	if Data != null and "player_username" in Data:
		var candidate := String(Data.player_username).strip_edges()
		if candidate != "":
			username = candidate
	title_label.text = "Pause - Pillars (%s)" % username
	var df: Node = Data.day_flow()
	if df != null and df.has_method("objective_text"):
		objective_label.text = df.objective_text()
	var pl: Node = Data.pillars()
	if pl != null and pl.has_method("get_pillar"):
		_set_label(wellbeing_label, wellbeing_bar, "Wellbeing", pl.get_pillar("wellbeing"))
		_set_label(social_label, social_bar, "Social", pl.get_pillar("social"))
		_set_label(exercise_label, exercise_bar, "Exercise", pl.get_pillar("exercise"))
		_set_label(nutrition_label, nutrition_bar, "Nutrition", pl.get_pillar("nutrition"))
		_set_label(sleep_label, sleep_bar, "Sleep", pl.get_pillar("sleep"))
		if pl.has_method("get_stat"):
			global_stats_label.text = (
				"Totals  XP:+%d  Items:%d  Nutrition:%d  Dropped:%d  Mini-games:%d"
				% [
					pl.get_stat("total_xp_earned"),
					pl.get_stat("items_carted"),
					pl.get_stat("nutrition_earned"),
					pl.get_stat("foods_dropped"),
					pl.get_stat("mini_games_played")
				]
			)

func _set_label(label: Label, bar: ProgressBar, title: String, pillar: Dictionary) -> void:
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

func _find_traveler_notebook() -> Node:
	var scene := get_tree().current_scene
	if scene != null:
		var n := scene.get_node_or_null("TravelerNotebook")
		if n != null:
			return n
		n = scene.find_child("TravelerNotebook", true, false)
		if n != null:
			return n
	var from_group := get_tree().get_first_node_in_group("traveler_notebook")
	if from_group != null:
		return from_group
	return null

func _open_notebook() -> void:
	var notebook := _find_traveler_notebook()
	if notebook == null:
		return
	get_tree().paused = false
	panel.visible = false
	inventory_panel.visible = false
	if notebook.has_method("show_panel_from_pause"):
		notebook.show_panel_from_pause(_player, self)
	elif notebook.has_method("show_panel"):
		notebook.show_panel(_player)

func _open_inventory() -> void:
	_refresh_inventory_ui()
	panel.visible = false
	inventory_panel.visible = true

func _refresh_inventory_ui() -> void:
	var inv := Data.get_convenience_inventory()
	inventory_list.clear()
	_inventory_keys.clear()
	if inv.is_empty():
		eat_hint_label.text = "No convenience-store ingredients yet."
		eat_button.disabled = true
	else:
		var keys := inv.keys()
		keys.sort()
		for k in keys:
			var item_name := str(k)
			inventory_list.add_item("%s x%d" % [item_name, int(inv[k])])
			_inventory_keys.append(item_name)
		eat_hint_label.text = "Select an ingredient, then eat it for a boost."
		eat_button.disabled = false

func _close_inventory() -> void:
	inventory_panel.visible = false
	panel.visible = true

func _eat_selected_inventory_item() -> void:
	var selected := inventory_list.get_selected_items()
	if selected.is_empty():
		eat_hint_label.text = "Select an ingredient first."
		return
	var idx := int(selected[0])
	if idx < 0 or idx >= _inventory_keys.size():
		return
	var item_name := _inventory_keys[idx]
	if not Data.consume_convenience_ingredient(item_name, 1):
		eat_hint_label.text = "Could not eat " + item_name + "."
		return
	print("Ate ", item_name, " -> ", _get_food_boost_debug_text(item_name))
	eat_hint_label.text = "Ate %s! %s" % [item_name, _get_food_boost_debug_text(item_name)]
	_refresh_inventory_ui()

func _get_food_boost_debug_text(item_name: String) -> String:
	match item_name:
		"Apple", "Banana", "Salad", "Carrot Sticks", "Water":
			return "Placeholder boost: +Wellbeing regen."
		"Granola Bar", "Juice Box", "Crackers", "Yogurt", "Trail Mix":
			return "Placeholder boost: +Focus for class."
		"Chips", "Candy Bar", "Soda", "Cookies", "Donut":
			return "Placeholder boost: +Speed burst, then crash."
		_:
			return "Placeholder boost: generic nutrition effect."
