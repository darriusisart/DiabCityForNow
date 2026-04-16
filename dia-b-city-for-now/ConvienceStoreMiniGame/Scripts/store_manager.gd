extends Node2D
## Main controller for the Convenience Store Simulator.
## Manages shelves, food cards, shopping cart, timer, drag-and-drop,
## mini-game triggers, and the end-game screen.

# ─── Collision Masks (mirroring Take2 pattern) ───
const COLLISION_MASK_FOOD = 1
const COLLISION_MASK_CART = 2

# ─── Layout Constants ───
const GAME_TIME := 60
const MAX_ROUNDS := 3
const RETURN_SCENE_PATH := "res://DiabWorld/scenes/convenience_world.tscn"
const ROUND_TIME := 20.0

var shelf_top_y := 125.0
var shelf_mid_y := 375.0
var shelf_bot_y := 625.0
var shelf_width := 1600.0
var shelf_height := 500.0
var shelf_x := 10.0

var cart_x := 2150.0
var cart_y := 100.0
var cart_w := 1500.0
var cart_h := 2000.0

const CARD_W := 100
const CARD_H := 100
const GREEN_TIER_MULT := 1.35
const YELLOW_TIER_MULT := 1.0
const RED_TIER_MULT := 0.45
const NATURAL_INGREDIENTS := ["apple", "banana", "carrot", "water", "oats", "nuts", "milk", "cocoa"]
const MODERATE_INGREDIENTS := ["cane sugar", "salt", "citric acid", "fruit concentrate", "natural flavor"]
const BAD_INGREDIENTS := ["high fructose corn syrup", "artificial color", "preservative BHT", "palm oil", "corn syrup"]
const FOOD_INGREDIENTS := {
	"Apple": "apple",
	"Banana": "banana",
	"Carrot Sticks": "carrot, sea salt",
	"Salad": "romaine, tomato, cucumber, olive oil",
	"Water": "filtered water",
	"Spinach Wrap": "spinach tortilla, chicken, tomato, hummus",
	"Berry Cup": "strawberry, blueberry, blackberry",
	"Avocado Toast": "whole grain bread, avocado, lemon juice",
	"Bean Bowl": "black beans, brown rice, corn, salsa",
	"Greek Yogurt": "cultured milk, live probiotics",
	"Orange Slices": "orange",
	"Hummus Plate": "chickpeas, tahini, lemon juice, garlic",
	"Cucumber Sticks": "cucumber, sea salt",
	"Chicken Salad": "chicken, lettuce, tomato, olive oil",
	"Fruit Smoothie": "banana, strawberry, yogurt, water",
	"Granola Bar": "rolled oats, honey, nuts",
	"Juice Box": "fruit juice concentrate, water, vitamin c",
	"Crackers": "wheat flour, canola oil, sea salt",
	"Yogurt": "cultured milk, sugar",
	"Trail Mix": "raisins, peanuts, almonds, sunflower seeds",
	"Protein Bar": "milk protein, oats, cocoa, cane sugar",
	"Cheese Sticks": "pasteurized milk, salt, enzymes",
	"Pretzels": "wheat flour, yeast, salt",
	"Bagel Bites": "bagel dough, tomato sauce, mozzarella",
	"Cereal Cup": "whole grain oats, sugar, vitamins",
	"Flavored Milk": "milk, cocoa, cane sugar",
	"Fruit Gummies": "fruit puree, gelatin, sugar",
	"Rice Cakes": "brown rice, sea salt",
	"Pita Chips": "pita bread, sunflower oil, salt",
	"Snack Mix": "corn, peanuts, pretzels, seasoning",
	"Chips": "potatoes, vegetable oil, salt",
	"Candy Bar": "sugar, cocoa butter, milk solids",
	"Soda": "carbonated water, high fructose corn syrup, phosphoric acid",
	"Cookies": "flour, sugar, palm oil, chocolate chips",
	"Donut": "flour, sugar, palm oil, glaze",
	"Frosted Cake": "flour, sugar, palm oil, artificial color",
	"Energy Soda": "carbonated water, corn syrup, caffeine",
	"Caramel Pop": "corn syrup, sugar, butter flavor",
	"Chocolate Bites": "sugar, cocoa, palm oil",
	"Sugary Cereal": "refined grain, sugar, artificial color",
	"Iced Pastry": "flour, corn syrup, palm oil, icing",
	"Cheese Puffs": "corn meal, vegetable oil, cheese powder",
	"Gummy Rope": "corn syrup, sugar, gelatin, color",
	"Cream Cookie": "flour, sugar, palm oil, cream filling",
	"Fizzy Punch": "carbonated water, corn syrup, artificial flavor"
}

#---- Food Definitions ----
# Green (top shelf) - healthy, high nutrition
var all_green_foods := [
	{"name": "Apple",         "nutrition": 28},
	{"name": "Banana",        "nutrition": 25},
	{"name": "Carrot Sticks", "nutrition": 30},
	{"name": "Salad",         "nutrition": 32},
	{"name": "Water",         "nutrition": 22},
	{"name": "Spinach Wrap",  "nutrition": 29},
	{"name": "Berry Cup",     "nutrition": 27},
	{"name": "Avocado Toast", "nutrition": 26},
	{"name": "Bean Bowl",     "nutrition": 31},
	{"name": "Greek Yogurt",  "nutrition": 28},
	{"name": "Orange Slices", "nutrition": 24},
	{"name": "Hummus Plate",  "nutrition": 30},
	{"name": "Cucumber Sticks","nutrition": 23},
	{"name": "Chicken Salad", "nutrition": 33},
	{"name": "Fruit Smoothie","nutrition": 26},
]
# Yellow (middle shelf) - moderate
var all_yellow_foods := [
	{"name": "Granola Bar", "nutrition": 16},
	{"name": "Juice Box",  "nutrition": 14},
	{"name": "Crackers",   "nutrition": 12},
	{"name": "Yogurt",     "nutrition": 18},
	{"name": "Trail Mix",  "nutrition": 15},
	{"name": "Protein Bar", "nutrition": 17},
	{"name": "Cheese Sticks","nutrition": 14},
	{"name": "Pretzels",    "nutrition": 11},
	{"name": "Bagel Bites", "nutrition": 13},
	{"name": "Cereal Cup",  "nutrition": 15},
	{"name": "Flavored Milk","nutrition": 14},
	{"name": "Fruit Gummies","nutrition": 10},
	{"name": "Rice Cakes",  "nutrition": 12},
	{"name": "Pita Chips",  "nutrition": 11},
	{"name": "Snack Mix",   "nutrition": 16},
]
# Red (bottom shelf) - junk, low nutrition
var all_red_foods := [
	{"name": "Chips",     "nutrition": 4},
	{"name": "Candy Bar", "nutrition": 3},
	{"name": "Soda",      "nutrition": 2},
	{"name": "Cookies",   "nutrition": 5},
	{"name": "Donut",     "nutrition": 3},
	{"name": "Frosted Cake","nutrition": 2},
	{"name": "Energy Soda","nutrition": 2},
	{"name": "Caramel Pop","nutrition": 4},
	{"name": "Chocolate Bites","nutrition": 3},
	{"name": "Sugary Cereal","nutrition": 4},
	{"name": "Iced Pastry","nutrition": 3},
	{"name": "Cheese Puffs","nutrition": 3},
	{"name": "Gummy Rope","nutrition": 2},
	{"name": "Cream Cookie","nutrition": 4},
	{"name": "Fizzy Punch","nutrition": 2},
]
var green_foods: Array = []
var yellow_foods: Array = []
var red_foods: Array = []

# --- Runtime State ---
var screen_size : Vector2
var time_remaining : float = GAME_TIME
var game_active : bool = true

var card_being_dragged = null
var drag_origin : Vector2 = Vector2.ZERO

var cart_items : Array = []
var total_nutrition : int = 0
var foods_dropped : int = 0
var mini_games_played : int = 0
var current_round : int = 1

# --- Node References (built in _ready) ---
var timer_label : Label
var score_label : Label
var cart_count_label : Label
var hint_label : Label
var round_label : Label
var mini_game_mgr   # MiniGameManager node

# - Pending grab (waiting for mini-game result) -
var pending_card = null

# ──────────────────────────────────────────────
#  SETUP
# ──────────────────────────────────────────────
func _ready() -> void:
	screen_size = get_viewport_rect().size
	time_remaining = ROUND_TIME
	randomize()
	_set_round_inventory(current_round)
	_setup_layout_metrics()
	_build_background()
	_build_shelves()
	_build_cart()
	_build_hud()
	_populate_shelves()
	_setup_mini_game_manager()

func _setup_layout_metrics() -> void:
	cart_w = minf(360.0, screen_size.x * 0.24)
	cart_h = screen_size.y - 120.0
	cart_x = screen_size.x - cart_w - 24.0
	cart_y = 60.0

	shelf_x = 20.0
	shelf_width = cart_x - shelf_x - 20.0
	var playable_h := screen_size.y - 180.0
	shelf_height = maxf(120.0, playable_h / 3.0 - 10.0)
	shelf_top_y = 80.0
	shelf_mid_y = shelf_top_y + shelf_height + 20.0
	shelf_bot_y = shelf_mid_y + shelf_height + 20.0

# ── Background ──
func _build_background():
	var bg = ColorRect.new()
	bg.set_anchors_preset(15)
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
	#DIDNT EFFECT IT title.set_size(Vector2(0, 0))
	add_child(title)

# ── Three Shelves ──
func _build_shelves():
	_build_one_shelf("top",    shelf_top_y, Color(0.25, 0.72, 0.25, 0.25), "Healthy  (Green)")
	_build_one_shelf("middle", shelf_mid_y, Color(0.90, 0.78, 0.18, 0.25), "Moderate (Yellow)")
	_build_one_shelf("bottom", shelf_bot_y, Color(0.90, 0.28, 0.28, 0.25), "Junk Food (Red)")

func _build_one_shelf(id: String, y: float, tint: Color, text: String):
	# Shelf tinted area
	var rect = ColorRect.new()
	rect.name = "Shelf_" + id
	rect.color = tint
	rect.size = Vector2(shelf_width, shelf_height)
	rect.position = Vector2(shelf_x, y)
	add_child(rect)

	# Wooden platform bar
	var bar = ColorRect.new()
	bar.color = Color(0.50, 0.34, 0.18)
	bar.size = Vector2(shelf_width, 8)
	bar.position = Vector2(shelf_x, y + shelf_height - 8)
	add_child(bar)

	# Label
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(shelf_x + 6, y + 4)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	add_child(lbl)

# ── Shopping Cart ──
func _build_cart():
	# Cart background
	var bg = ColorRect.new()
	bg.name = "CartBg"
	bg.color = Color(0.55, 0.50, 0.44, 0.35)
	bg.size = Vector2(cart_w, cart_h)
	bg.position = Vector2(cart_x, cart_y)
	add_child(bg)

	# Top border
	var border_top = ColorRect.new()
	border_top.color = Color(0.38, 0.26, 0.14)
	border_top.size = Vector2(cart_w, 6)
	border_top.position = Vector2(cart_x, cart_y)
	add_child(border_top)

	# Cart title
	var lbl = Label.new()
	lbl.text = "Shopping Cart"
	lbl.position = Vector2(cart_x + 30, cart_y + 12)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.22, 0.16, 0.10))
	add_child(lbl)

	# Item count
	cart_count_label = Label.new()
	cart_count_label.name = "CartCount"
	cart_count_label.text = "Items: 0"
	cart_count_label.position = Vector2(cart_x + 30, cart_y + 42)
	cart_count_label.add_theme_font_size_override("font_size", 14)
	cart_count_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	add_child(cart_count_label)

	# Drop-zone Area2D (for raycast collision)
	var area = Area2D.new()
	area.name = "CartArea"
	area.position = Vector2(cart_x + cart_w / 2, cart_y + cart_h / 2)
	area.collision_layer = COLLISION_MASK_CART
	area.collision_mask  = COLLISION_MASK_CART
	var shape = CollisionShape2D.new()
	var r = RectangleShape2D.new()
	r.size = Vector2(cart_w, cart_h)
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
	hint_label.text = "Drag food into your cart. Right-click any item to flip and inspect ingredients."
	hint_label.position = Vector2(30, screen_size.y - 36)
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	ui.add_child(hint_label)

	round_label = Label.new()
	round_label.text = "Round: %d/%d" % [current_round, MAX_ROUNDS]
	round_label.position = Vector2(30, 10)
	round_label.add_theme_font_size_override("font_size", 22)
	round_label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.55))
	ui.add_child(round_label)

	_sync_score_hud_for_round()

func _sync_score_hud_for_round() -> void:
	if score_label == null:
		return
	score_label.visible = current_round <= 1

# -- Mini-Game Manager (separate script) --
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

	_spawn_row(card_mgr, green_foods,  "green",  shelf_top_y)
	_spawn_row(card_mgr, yellow_foods, "yellow", shelf_mid_y)
	_spawn_row(card_mgr, red_foods,    "red",    shelf_bot_y)

func _spawn_row(parent: Node2D, foods: Array, tier: String, shelf_y: float):
	for i in range(foods.size()):
		var card = _create_food_card(foods[i], tier)
		card.position = Vector2(shelf_x + 200 + i * (CARD_W + 24), _shelf_line_y(shelf_y + 50))
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
	card.set_meta("flipped", false)
	card.set_meta("quality", _quality_from_tier(tier))
	var base_ing := _ingredients_for_food(str(info["name"]), tier)
	var ing_for_label := base_ing
	if randf() < 0.5:
		ing_for_label = _misleading_ingredient_line(str(info["name"]), tier)
	card.set_meta("ingredients_text", ing_for_label)
	card.set_meta("nutrition_value", _weighted_nutrition_value(int(info["nutrition"]), tier))

	# Tier colour
	var tier_color : Color
	match tier:
		"green":  tier_color = Color(0.22, 0.74, 0.28)
		"yellow": tier_color = Color(0.88, 0.78, 0.20)
		"red":    tier_color = Color(0.86, 0.24, 0.24)
	if current_round > 1:
		tier_color = Color(0.52, 0.52, 0.52)

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
	plbl.text = "Score +" + str(card.get_meta("nutrition_value"))
	plbl.position = Vector2(-CARD_W / 2 + 6, -CARD_H / 2 + 28)
	plbl.add_theme_font_size_override("font_size", 11)
	plbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	plbl.visible = current_round <= 1
	card.add_child(plbl)

	var ingr := RichTextLabel.new()
	ingr.name = "IngredientsLabel"
	ingr.bbcode_enabled = true
	ingr.fit_content = false
	ingr.scroll_active = false
	ingr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ingr.z_index = 2
	ingr.size = Vector2(CARD_W - 14, CARD_H - 48)
	ingr.position = Vector2(-CARD_W / 2 + 7, -CARD_H / 2 + 40)
	ingr.visible = false
	card.add_child(ingr)

	# Tier icon
	var icon_text := ""
	match tier:
		"green":  icon_text = "GRN"
		"yellow": icon_text = "YLW"
		"red":    icon_text = "RED"
	if current_round > 1:
		icon_text = "???"
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
	_set_card_face(card, false)

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
		_advance_to_next_round_or_end()
		return
	timer_label.text = _format_time(time_remaining)

	# Flash timer red near round end
	if time_remaining < 10.0:
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
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		_exit_to_convenience_world()
		return

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
			# Left click is the only way to trigger mini-games.
			if card_being_dragged:
				return
			var card = _raycast_for_food()
			if card and not card.get_meta("in_cart") and not card.get_meta("dropped"):
				var tier = card.get_meta("tier")
				if tier == "red":
					# Bottom shelf - grab directly (no mini-game).
					_start_drag(card)
				elif tier == "yellow":
					pending_card = card
					mini_game_mgr.start_random("yellow", _card_data_for_mini_game(card))
					mini_games_played += 1
				elif tier == "green":
					pending_card = card
					mini_game_mgr.start_random("green", _card_data_for_mini_game(card))
					mini_games_played += 1
		else:
			if card_being_dragged:
				_finish_drag()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right click only flips the card to inspect ingredients.
		if card_being_dragged:
			return
		var card2 = _raycast_for_food()
		if card2 and not card2.get_meta("in_cart") and not card2.get_meta("dropped"):
			var flipped := not bool(card2.get_meta("flipped"))
			_set_card_face(card2, flipped)
			if flipped:
				hint_label.text = "Ingredients for %s: %s" % [str(card2.get_meta("food_name")), str(card2.get_meta("ingredients_text"))]
			else:
				hint_label.text = "Front of card: %s" % str(card2.get_meta("food_name"))

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
		# Dropped outside cart - lost forever
		_drop_food(card)

func _add_to_cart(card):
	card.set_meta("in_cart", true)
	card.get_node("Area2D/CollisionShape2D").disabled = true

	# Place nicely in cart grid
	var idx = cart_items.size()
	var col = idx % 2
	var row = idx / 2
	var target = Vector2(cart_x + 20 + col * (CARD_W * 0.65 + 8),
						  cart_y + 70 + row * (CARD_H * 0.65 + 6))
	var tw = create_tween()
	tw.tween_property(card, "position", target, 0.25).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(card, "scale", Vector2(0.65, 0.65), 0.25)
	card.z_index = 1

	cart_items.append(card)
	total_nutrition += int(card.get_meta("nutrition_value"))
	Data.add_convenience_ingredient(str(card.get_meta("food_name")), 1)
	if current_round <= 1:
		score_label.text = "Nutrition: " + str(total_nutrition)
	cart_count_label.text = "Items: " + str(cart_items.size())
	if current_round <= 1:
		hint_label.text = "Got " + card.get_meta("food_name") + "!  (+" + str(card.get_meta("nutrition_value")) + " nutrition)"
	else:
		hint_label.text = "Got " + str(card.get_meta("food_name")) + "!"

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
		var food_name := str(card.get_meta("food_name"))
		var nutrition := int(card.get_meta("nutrition"))
		var tier := str(card.get_meta("tier")).capitalize()
		if current_round <= 1:
			hint_label.text = "%s ingredient: %s | Base nutrition: %d" % [tier, food_name, nutrition]
		else:
			hint_label.text = "%s: %s" % [tier, food_name]
	else:
		card.scale = Vector2(1.0, 1.0)
		card.z_index = 1
		hint_label.text = "Drag food into your cart. Right-click any item to flip and inspect ingredients."

# ──────────────────────────────────────────────
#  MINI-GAME CALLBACK
# ──────────────────────────────────────────────
func _is_mini_game_active() -> bool:
	return mini_game_mgr and mini_game_mgr.active

func _on_mini_game_finished(success: bool):
	if success and pending_card:
		var bonus: int = 0
		if mini_game_mgr != null and mini_game_mgr.has_method("consume_last_ingredient_bonus"):
			bonus = int(mini_game_mgr.consume_last_ingredient_bonus())
		if bonus != 0:
			var cur := int(pending_card.get_meta("nutrition_value"))
			var updated: int = max(1, cur + bonus)
			pending_card.set_meta("nutrition_value", updated)
			var plbl: Label = pending_card.get_node_or_null("PtsLabel") as Label
			if plbl != null:
				plbl.text = "Score +" + str(updated)
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
	_record_run_stats()
	# Load end-screen script
	var end_scr = preload("res://ConvienceStoreMiniGame/Scripts/end_screen.gd")
	var end_node = Node2D.new()
	end_node.name = "EndScreen"
	#end_node.set_script(end_scr)
	add_child(end_node)
	end_node.show_results(cart_items, total_nutrition, foods_dropped, mini_games_played, screen_size)

func _record_run_stats() -> void:
	var pl: Node = Data.pillars()
	if pl == null or not pl.has_method("add_stat"):
		return
	pl.add_stat("items_carted", cart_items.size())
	pl.add_stat("nutrition_earned", total_nutrition)
	pl.add_stat("foods_dropped", foods_dropped)
	pl.add_stat("mini_games_played", mini_games_played)
	if pl.has_method("add_xp"):
		var grade := _calc_nutrition_grade(cart_items.size(), total_nutrition)
		var xp := _nutrition_xp_from_grade(grade)
		pl.add_xp("nutrition", xp, "convenience_store_" + grade)

func _calc_nutrition_grade(item_count: int, nutrition_sum: int) -> String:
	if item_count <= 0:
		return "F"
	var avg := float(nutrition_sum) / float(item_count)
	if avg >= 26.0:
		return "S"
	if avg >= 21.0:
		return "A"
	if avg >= 16.0:
		return "B"
	if avg >= 11.0:
		return "C"
	if avg >= 6.0:
		return "D"
	return "F"

func _nutrition_xp_from_grade(grade: String) -> int:
	match grade:
		"S": return 30
		"A": return 24
		"B": return 18
		"C": return 12
		"D": return 8
		_: return 4

func _advance_to_next_round_or_end() -> void:
	if _is_mini_game_active():
		mini_game_mgr.force_close()
		pending_card = null
	if current_round >= MAX_ROUNDS:
		time_remaining = 0.0
		timer_label.text = _format_time(time_remaining)
		_end_game()
		return
	current_round += 1
	_sync_score_hud_for_round()
	round_label.text = "Round: %d/%d" % [current_round, MAX_ROUNDS]
	time_remaining = ROUND_TIME
	timer_label.text = _format_time(time_remaining)
	timer_label.add_theme_color_override("font_color", Color(0.82, 0.12, 0.12))
	_reset_aisle_for_round()

func _reset_aisle_for_round() -> void:
	_set_round_inventory(current_round)
	var card_mgr := get_node_or_null("CardManager")
	if card_mgr == null:
		return
	for c in card_mgr.get_children():
		if bool(c.get_meta("in_cart")):
			continue
		c.queue_free()
	_spawn_row(card_mgr, green_foods, "green", shelf_top_y)
	_spawn_row(card_mgr, yellow_foods, "yellow", shelf_mid_y)
	_spawn_row(card_mgr, red_foods, "red", shelf_bot_y)
	hint_label.text = "Aisle %d restocked with new items." % current_round

func _next_round_position(_tier: String) -> Vector2:
	var min_x := shelf_x + CARD_W * 0.5
	var max_x := shelf_x + shelf_width - CARD_W * 0.5
	var x := randf_range(min_x, max_x)
	if current_round == 2 and randf() < 0.15:
		# Keep a small bit of tier structure in round 2.
		return Vector2(x, _shelf_line_y(shelf_mid_y))
	var shelves: Array[float] = [shelf_top_y, shelf_mid_y, shelf_bot_y]
	var chosen_y: float = shelves[randi() % shelves.size()]
	var y2 := _shelf_line_y(chosen_y)
	return Vector2(x, y2)

func _set_round_inventory(round_num: int) -> void:
	green_foods = _foods_for_round(all_green_foods, round_num, 5)
	yellow_foods = _foods_for_round(all_yellow_foods, round_num, 5)
	red_foods = _foods_for_round(all_red_foods, round_num, 5)

func _foods_for_round(pool: Array, round_num: int, count: int) -> Array:
	if pool.is_empty():
		return []
	var working := pool.duplicate(true)
	working.shuffle()
	var start: int = ((round_num - 1) * count) % max(1, working.size())
	var out: Array = []
	for i in range(count):
		out.append(working[(start + i) % working.size()])
	return out

func _card_data_for_mini_game(card: Node2D) -> Dictionary:
	return {
		"food_name": str(card.get_meta("food_name")),
		"quality": str(card.get_meta("quality")),
		"ingredients_text": str(card.get_meta("ingredients_text"))
	}

func _shelf_line_y(shelf_y: float) -> float:
	return shelf_y + (shelf_height - CARD_H) * 0.5 + 10.0

func _weighted_nutrition_value(base_nutrition: int, tier: String) -> int:
	var mult := YELLOW_TIER_MULT
	match tier:
		"green":
			mult = GREEN_TIER_MULT
		"red":
			mult = RED_TIER_MULT
	var score := int(round(float(base_nutrition) * mult))
	return max(1, score)

func _quality_from_tier(tier: String) -> String:
	match tier:
		"green":
			return "natural"
		"yellow":
			return "moderate"
		_:
			return "bad"

func _ingredients_for_food(food_name: String, tier: String) -> String:
	if FOOD_INGREDIENTS.has(food_name):
		return str(FOOD_INGREDIENTS[food_name])
	return _ingredients_for_tier(tier)

func _misleading_ingredient_line(food_name: String, _tier: String) -> String:
	# Looks like junk food — 50/50 the label lies; minigame answer still uses true tier quality.
	return "high fructose corn syrup, artificial %s flavor, palm oil, TBHQ, red 40, corn starch" % food_name.replace(" ", "_").to_lower()

func _ingredients_for_tier(tier: String) -> String:
	var out := PackedStringArray()
	if tier == "green":
		out.append_array([NATURAL_INGREDIENTS[randi() % NATURAL_INGREDIENTS.size()], NATURAL_INGREDIENTS[randi() % NATURAL_INGREDIENTS.size()]])
	elif tier == "yellow":
		out.append_array([NATURAL_INGREDIENTS[randi() % NATURAL_INGREDIENTS.size()], MODERATE_INGREDIENTS[randi() % MODERATE_INGREDIENTS.size()], MODERATE_INGREDIENTS[randi() % MODERATE_INGREDIENTS.size()]])
	else:
		out.append_array([BAD_INGREDIENTS[randi() % BAD_INGREDIENTS.size()], MODERATE_INGREDIENTS[randi() % MODERATE_INGREDIENTS.size()], BAD_INGREDIENTS[randi() % BAD_INGREDIENTS.size()]])
	return ", ".join(out)

func _set_card_face(card: Node2D, flipped: bool) -> void:
	card.set_meta("flipped", flipped)
	var name_lbl := card.get_node_or_null("NameLabel")
	var pts_lbl := card.get_node_or_null("PtsLabel")
	var ingr_lbl := card.get_node_or_null("IngredientsLabel")
	var icon_lbl := card.get_node_or_null("TierIcon")
	if name_lbl: name_lbl.visible = not flipped
	if pts_lbl:
		pts_lbl.visible = (not flipped) and (current_round <= 1)
	if icon_lbl: icon_lbl.visible = not flipped
	if ingr_lbl:
		ingr_lbl.visible = flipped
		if flipped:
			if current_round <= 1:
				var quality := str(card.get_meta("quality"))
				ingr_lbl.text = "[b]Ingredients[/b]\n%s\n\n[b]Quality:[/b] %s" % [str(card.get_meta("ingredients_text")), quality.capitalize()]
			else:
				ingr_lbl.text = "[b]Ingredients[/b]\n%s" % str(card.get_meta("ingredients_text"))

func _exit_to_convenience_world() -> void:
	get_tree().change_scene_to_file(RETURN_SCENE_PATH)
