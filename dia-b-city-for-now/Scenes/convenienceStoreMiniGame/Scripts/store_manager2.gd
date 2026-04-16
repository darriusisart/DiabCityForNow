extends Node2D
## Main controller for the Convenience Store Simulator.
## Manages shelves, food cards, shopping cart, timer, drag-and-drop,
## mini-game triggers, and the end-game screen.

# ─── Collision Masks (mirroring Take2 pattern) ───
const COLLISION_MASK_FOOD = 1
const COLLISION_MASK_CART = 2

# ─── Layout Constants ───
const GAME_TIME := 180.0

const SHELF_TOP_Y := 80
const SHELF_MID_Y := 250
const SHELF_BOT_Y := 420
const SHELF_WIDTH := 680
const SHELF_HEIGHT := 130
const SHELF_X := 30

const CART_X := 780
const CART_Y := 100
const CART_W := 220
const CART_H := 480

const CARD_W := 110
const CARD_H := 85

# ─── Food Definitions ───
# Green (top shelf) – healthy, high nutrition
var green_foods := [
	{"name": "Apple",         "nutrition": 28},
	{"name": "Banana",        "nutrition": 25},
	{"name": "Carrot Sticks", "nutrition": 30},
	{"name": "Salad",         "nutrition": 32},
	{"name": "Water",         "nutrition": 22},
]
# Yellow (middle shelf) – moderate
var yellow_foods := [
	{"name": "Granola Bar", "nutrition": 16},
	{"name": "Juice Box",  "nutrition": 14},
	{"name": "Crackers",   "nutrition": 12},
	{"name": "Yogurt",     "nutrition": 18},
	{"name": "Trail Mix",  "nutrition": 15},
]
# Red (bottom shelf) – junk, low nutrition
var red_foods := [
	{"name": "Chips",     "nutrition": 4},
	{"name": "Candy Bar", "nutrition": 3},
	{"name": "Soda",      "nutrition": 2},
	{"name": "Cookies",   "nutrition": 5},
	{"name": "Donut",     "nutrition": 3},
]

# ─── Runtime State ───
var screen_size : Vector2
var time_remaining : float = GAME_TIME
var game_active : bool = true

var card_being_dragged = null
var drag_origin : Vector2 = Vector2.ZERO

var cart_items : Array = []
var total_nutrition : int = 0
var foods_dropped : int = 0
var mini_games_played : int = 0

# ─── Node References (built in _ready) ───
var timer_label : Label
var score_label : Label
var cart_count_label : Label
var hint_label : Label
var mini_game_mgr   # MiniGameManager node

# ─── Pending grab (waiting for mini-game result) ───
var pending_card = null

# ──────────────────────────────────────────────
#  SETUP
# ──────────────────────────────────────────────
func _ready() -> void:
	screen_size = get_viewport_rect().size
	randomize()
	_build_background()
	_build_shelves()
	_build_cart()
	_build_hud()
	_populate_shelves()
	_setup_mini_game_manager()

# ── Background ──
func _build_background():
	var bg = ColorRect.new()
	bg.color = Color(0.96, 0.94, 0.89)
	bg.size = screen_size
	bg.z_index = -10
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "Corner Store"
	title.position = Vector2(screen_size.x / 2 - 80, 8)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.22, 0.16, 0.10))
	add_child(title)

# ── Three Shelves ──
func _build_shelves():
	_build_one_shelf("top",    SHELF_TOP_Y, Color(0.25, 0.72, 0.25, 0.25), "Healthy  (Green)")
	_build_one_shelf("middle", SHELF_MID_Y, Color(0.90, 0.78, 0.18, 0.25), "Moderate (Yellow)")
	_build_one_shelf("bottom", SHELF_BOT_Y, Color(0.90, 0.28, 0.28, 0.25), "Junk Food (Red)")

func _build_one_shelf(id: String, y: float, tint: Color, text: String):
	# Shelf tinted area
	var rect = ColorRect.new()
	rect.name = "Shelf_" + id
	rect.color = tint
	rect.size = Vector2(SHELF_WIDTH, SHELF_HEIGHT)
	rect.position = Vector2(SHELF_X, y)
	add_child(rect)

	# Wooden platform bar
	var bar = ColorRect.new()
	bar.color = Color(0.50, 0.34, 0.18)
	bar.size = Vector2(SHELF_WIDTH, 8)
	bar.position = Vector2(SHELF_X, y + SHELF_HEIGHT - 8)
	add_child(bar)

	# Label
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(SHELF_X + 6, y + 4)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	add_child(lbl)

# ── Shopping Cart ──
func _build_cart():
	# Cart background
	var bg = ColorRect.new()
	bg.name = "CartBg"
	bg.color = Color(0.55, 0.50, 0.44, 0.35)
	bg.size = Vector2(CART_W, CART_H)
	bg.position = Vector2(CART_X, CART_Y)
	add_child(bg)

	# Top border
	var border_top = ColorRect.new()
	border_top.color = Color(0.38, 0.26, 0.14)
	border_top.size = Vector2(CART_W, 6)
	border_top.position = Vector2(CART_X, CART_Y)
	add_child(border_top)

	# Cart title
	var lbl = Label.new()
	lbl.text = "Shopping Cart"
	lbl.position = Vector2(CART_X + 30, CART_Y + 12)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.22, 0.16, 0.10))
	add_child(lbl)

	# Item count
	cart_count_label = Label.new()
	cart_count_label.name = "CartCount"
	cart_count_label.text = "Items: 0"
	cart_count_label.position = Vector2(CART_X + 30, CART_Y + 42)
	cart_count_label.add_theme_font_size_override("font_size", 14)
	cart_count_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	add_child(cart_count_label)

	# Drop-zone Area2D (for raycast collision)
	var area = Area2D.new()
	area.name = "CartArea"
	area.position = Vector2(CART_X + CART_W / 2, CART_Y + CART_H / 2)
	area.collision_layer = COLLISION_MASK_CART
	area.collision_mask  = COLLISION_MASK_CART
	var shape = CollisionShape2D.new()
	var r = RectangleShape2D.new()
	r.size = Vector2(CART_W, CART_H)
	shape.shape = r
	area.add_child(shape)
	add_child(area)

# ── HUD (timer, score, hint) ──
func _build_hud():
	var ui = CanvasLayer.new()
	ui.name = "HUD"
	add_child(ui)

	timer_label = Label.new()
	timer_label.text = _format_time(time_remaining)
	timer_label.position = Vector2(screen_size.x - 195, 12)
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color(0.82, 0.12, 0.12))
	ui.add_child(timer_label)

	score_label = Label.new()
	score_label.text = "Nutrition: 0"
	score_label.position = Vector2(screen_size.x - 195, 44)
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color(0.18, 0.62, 0.18))
	ui.add_child(score_label)

	hint_label = Label.new()
	hint_label.text = "Drag food from the shelves into your cart! Healthy food is up high!"
	hint_label.position = Vector2(30, screen_size.y - 36)
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	ui.add_child(hint_label)

# ── Mini-Game Manager (separate script) ──
func _setup_mini_game_manager():
	var mgr_scene = preload("res://ConvienceStoreMiniGame/Scripts/mini_game_manager.gd")
	var mgr = Node2D.new()
	mgr.name = "MiniGameManager"
	mgr.set_script(mgr_scene)
	add_child(mgr)
	mini_game_mgr = mgr
	mini_game_mgr.connect("mini_game_finished", _on_mini_game_finished)

# ──────────────────────────────────────────────
#  POPULATE SHELVES WITH FOOD CARDS
# ──────────────────────────────────────────────
func _populate_shelves():
	var card_mgr = Node2D.new()
	card_mgr.name = "CardManager"
	add_child(card_mgr)

	_spawn_row(card_mgr, green_foods,  "green",  SHELF_TOP_Y)
	_spawn_row(card_mgr, yellow_foods, "yellow", SHELF_MID_Y)
	_spawn_row(card_mgr, red_foods,    "red",    SHELF_BOT_Y)

func _spawn_row(parent: Node2D, foods: Array, tier: String, shelf_y: float):
	for i in range(foods.size()):
		var card = _create_food_card(foods[i], tier)
		card.position = Vector2(SHELF_X + 30 + i * (CARD_W + 16), shelf_y + (SHELF_HEIGHT - CARD_H) / 2 + 10)
		parent.add_child(card)

func _create_food_card(info: Dictionary, tier: String) -> Node2D:
	var card = Node2D.new()
	card.name = "Food_" + info["name"].replace(" ", "_")
	card.z_index = 1

	# Metadata
	card.set_meta("food_name", info["name"])
	card.set_meta("nutrition", info["nutrition"])
	card.set_meta("tier", tier)
	card.set_meta("in_cart", false)
	card.set_meta("dropped", false)

	# Tier colour
	var tier_color : Color
	match tier:
		"green":  tier_color = Color(0.22, 0.74, 0.28)
		"yellow": tier_color = Color(0.88, 0.78, 0.20)
		"red":    tier_color = Color(0.86, 0.24, 0.24)

	# Card border (slightly larger, behind)
	var border = ColorRect.new()
	border.name = "Border"
	border.color = Color(0.18, 0.14, 0.10)
	border.size = Vector2(CARD_W + 4, CARD_H + 4)
	border.position = Vector2(-CARD_W / 2 - 2, -CARD_H / 2 - 2)
	border.z_index = -1
	card.add_child(border)

	# Card background
	var bg = ColorRect.new()
	bg.name = "CardBg"
	bg.color = tier_color
	bg.size = Vector2(CARD_W, CARD_H)
	bg.position = Vector2(-CARD_W / 2, -CARD_H / 2)
	card.add_child(bg)

	# Food name
	var nlbl = Label.new()
	nlbl.name = "NameLabel"
	nlbl.text = info["name"]
	nlbl.position = Vector2(-CARD_W / 2 + 6, -CARD_H / 2 + 6)
	nlbl.add_theme_font_size_override("font_size", 14)
	nlbl.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(nlbl)

	# Nutrition points
	var plbl = Label.new()
	plbl.name = "PtsLabel"
	plbl.text = "+" + str(info["nutrition"]) + " pts"
	plbl.position = Vector2(-CARD_W / 2 + 6, -CARD_H / 2 + 28)
	plbl.add_theme_font_size_override("font_size", 11)
	plbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	card.add_child(plbl)

	# Tier icon
	var icon_text := ""
	match tier:
		"green":  icon_text = "GRN"
		"yellow": icon_text = "YLW"
		"red":    icon_text = "RED"
	var icon = Label.new()
	icon.name = "TierIcon"
	icon.text = icon_text
	icon.position = Vector2(CARD_W / 2 - 40, CARD_H / 2 - 24)
	icon.add_theme_font_size_override("font_size", 11)
	icon.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	card.add_child(icon)

	# Collision Area2D
	var area = Area2D.new()
	area.name = "Area2D"
	area.collision_layer = COLLISION_MASK_FOOD
	area.collision_mask  = COLLISION_MASK_FOOD
	var cshape = CollisionShape2D.new()
	cshape.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(CARD_W, CARD_H)
	cshape.shape = rect
	area.add_child(cshape)
	card.add_child(area)

	# Hover signals
	area.mouse_entered.connect(_on_card_hover.bind(card, true))
	area.mouse_exited.connect(_on_card_hover.bind(card, false))

	return card

# ──────────────────────────────────────────────
#  GAME LOOP
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	if not game_active:
		return

	# Timer
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_end_game()
		return
	timer_label.text = _format_time(time_remaining)

	# Flash timer red when < 30 s
	if time_remaining < 30.0:
		var flash = Color(1, 0, 0) if fmod(time_remaining, 1.0) > 0.5 else Color(0.5, 0, 0)
		timer_label.add_theme_color_override("font_color", flash)

	# Drag follow mouse
	if card_being_dragged and not _is_mini_game_active():
		var mp = get_global_mouse_position()
		card_being_dragged.position = Vector2(
			clamp(mp.x, 0, screen_size.x),
			clamp(mp.y, 0, screen_size.y)
		)

func _format_time(t: float) -> String:
	var m = int(t) / 60
	var s = int(t) % 60
	return "Time: %d:%02d" % [m, s]

# ──────────────────────────────────────────────
#  INPUT
# ──────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not game_active:
		# Restart
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return

	# Delegate to mini-game if active
	if _is_mini_game_active():
		return   # mini_game_manager handles its own input

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# If we're already dragging a card, ignore new clicks on food
			if card_being_dragged:
				return
			var card = _raycast_for_food()
			if card and not card.get_meta("in_cart") and not card.get_meta("dropped"):
				var tier = card.get_meta("tier")
				if tier == "red":
					# Bottom shelf – grab directly
					_start_drag(card)
				elif tier == "yellow":
					# Middle shelf – easy-to-medium mini-game required
					pending_card = card
					mini_game_mgr.start_random("yellow")
					mini_games_played += 1
				elif tier == "green":
					# Top shelf – harder mini-game required
					pending_card = card
					mini_game_mgr.start_random("green")
					mini_games_played += 1
		else:
			if card_being_dragged:
				_finish_drag()

# ──────────────────────────────────────────────
#  DRAG & DROP  (adapted from CardMiniGameTake2)
# ──────────────────────────────────────────────
func _start_drag(card):
	card_being_dragged = card
	drag_origin = card.position
	card.z_index = 10
	card.scale = Vector2(1.0, 1.0)
	hint_label.text = "Dragging " + card.get_meta("food_name") + " – drop it in the cart!"

func _finish_drag():
	var card = card_being_dragged
	card_being_dragged = null

	if _point_in_cart(get_global_mouse_position()):
		_add_to_cart(card)
	else:
		# Dropped outside cart → lost forever
		_drop_food(card)

func _add_to_cart(card):
	card.set_meta("in_cart", true)
	card.get_node("Area2D/CollisionShape2D").disabled = true

	# Place nicely in cart grid
	var idx = cart_items.size()
	var col = idx % 2
	var row = idx / 2
	var target = Vector2(CART_X + 20 + col * (CARD_W * 0.65 + 8),
						  CART_Y + 70 + row * (CARD_H * 0.65 + 6))
	var tw = create_tween()
	tw.tween_property(card, "position", target, 0.25).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(card, "scale", Vector2(0.65, 0.65), 0.25)
	card.z_index = 1

	cart_items.append(card)
	total_nutrition += card.get_meta("nutrition")
	score_label.text = "Nutrition: " + str(total_nutrition)
	cart_count_label.text = "Items: " + str(cart_items.size())
	hint_label.text = "Got " + card.get_meta("food_name") + "!  (+" + str(card.get_meta("nutrition")) + " nutrition)"

func _drop_food(card):
	card.set_meta("dropped", true)
	card.get_node("Area2D/CollisionShape2D").disabled = true
	foods_dropped += 1

	var tw = create_tween()
	tw.tween_property(card, "position",
		Vector2(card.position.x, screen_size.y + 60), 0.45).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(card, "modulate", Color(1, 1, 1, 0.25), 0.45)
	card.z_index = -1
	hint_label.text = card.get_meta("food_name") + " hit the floor! It's gone!"

# ──────────────────────────────────────────────
#  RAYCASTING  (same pattern as Take2)
# ──────────────────────────────────────────────
func _raycast_for_food():
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collision_mask = COLLISION_MASK_FOOD
	var hits = space.intersect_point(params)
	if hits.size() > 0:
		return _highest_z(hits)
	return null

func _point_in_cart(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collision_mask = COLLISION_MASK_CART
	return space.intersect_point(params).size() > 0

func _highest_z(hits: Array):
	var best = hits[0].collider.get_parent()
	for i in range(1, hits.size()):
		var c = hits[i].collider.get_parent()
		if c.z_index > best.z_index:
			best = c
	return best

# ──────────────────────────────────────────────
#  HOVER HIGHLIGHT
# ──────────────────────────────────────────────
func _on_card_hover(card, entering: bool):
	if card_being_dragged or card.get_meta("in_cart") or card.get_meta("dropped"):
		return
	if _is_mini_game_active():
		return
	if entering:
		card.scale = Vector2(1.08, 1.08)
		card.z_index = 3
	else:
		card.scale = Vector2(1.0, 1.0)
		card.z_index = 1

# ──────────────────────────────────────────────
#  MINI-GAME CALLBACK
# ──────────────────────────────────────────────
func _is_mini_game_active() -> bool:
	return mini_game_mgr and mini_game_mgr.active

func _on_mini_game_finished(success: bool):
	if success and pending_card:
		_start_drag(pending_card)
	elif pending_card:
		_drop_food(pending_card)
		hint_label.text = "Couldn't grab " + pending_card.get_meta("food_name") + "! It fell!"
	pending_card = null

# ──────────────────────────────────────────────
#  END GAME → SHOW SHOPKEEPER SCREEN
# ──────────────────────────────────────────────
func _end_game():
	game_active = false
	card_being_dragged = null
	# Load end-screen script
	var end_scr = preload("res://ConvienceStoreMiniGame/Scripts/end_screen.gd")
	var end_node = Node2D.new()
	end_node.name = "EndScreen"
	end_node.set_script(end_scr)
	add_child(end_node)
	end_node.show_results(cart_items, total_nutrition, foods_dropped, mini_games_played, screen_size)
