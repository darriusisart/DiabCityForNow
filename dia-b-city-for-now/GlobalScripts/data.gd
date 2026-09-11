extends Node

var class_points: int = 0
var convenience_inventory: Dictionary = {}
var player_username: String = "Student"
## Spine outfit (skin name from skeleton data) and per-slot RGBA tints { "slot_name": Color }.
var player_spine_skin: String = "Default"
var player_spine_slot_tints: Dictionary = {}
var player_spine_global_tint: Color = Color(1, 1, 1, 1)
## Per-slot attachment selections, ex: {"Hair": "hair_long_01", "Top": "hoodie_blue"}.
var player_spine_part_attachments: Dictionary = {}
var today_learning_notes: Array[String] = []
## Suika-style recess garden: merged seed count (from stacking two soil clumps).
var recess_garden_seeds: int = 0
var nutrition_energy_score: float = 0.0
var nutrition_speed_multiplier: float = 1.0

func add_learning_note(note: String) -> void:
	var clean := note.strip_edges()
	if clean == "":
		return
	today_learning_notes.append(clean)

func get_learning_notes() -> Array[String]:
	return today_learning_notes.duplicate()

## Convenience-store tiers — aligns green/yellow/red shelves in ConvienceStoreMiniGame Scripts.
const FOOD_QUALITY := {
	"Apple": "natural",
	"Banana": "natural",
	"Salad": "natural",
	"Carrot Sticks": "natural",
	"Water": "natural",
	"Spinach Wrap": "natural",
	"Berry Cup": "natural",
	"Avocado Toast": "natural",
	"Bean Bowl": "natural",
	"Greek Yogurt": "natural",
	"Orange Slices": "natural",
	"Hummus Plate": "natural",
	"Cucumber Sticks": "natural",
	"Chicken Salad": "natural",
	"Fruit Smoothie": "natural",
	"Granola Bar": "moderate",
	"Juice Box": "moderate",
	"Crackers": "moderate",
	"Yogurt": "moderate",
	"Trail Mix": "moderate",
	"Protein Bar": "moderate",
	"Cheese Sticks": "moderate",
	"Pretzels": "moderate",
	"Bagel Bites": "moderate",
	"Cereal Cup": "moderate",
	"Flavored Milk": "moderate",
	"Fruit Gummies": "moderate",
	"Rice Cakes": "moderate",
	"Pita Chips": "moderate",
	"Snack Mix": "moderate",
	"Chips": "bad",
	"Candy Bar": "bad",
	"Soda": "bad",
	"Cookies": "bad",
	"Donut": "bad",
	"Frosted Cake": "bad",
	"Energy Soda": "bad",
	"Caramel Pop": "bad",
	"Chocolate Bites": "bad",
	"Sugary Cereal": "bad",
	"Iced Pastry": "bad",
	"Cheese Puffs": "bad",
	"Gummy Rope": "bad",
	"Cream Cookie": "bad",
	"Fizzy Punch": "bad"
}

## Base nutrition per item (same as store_manager food defs) for shopkeeper scoring.
const FOOD_NUTRITION := {
	"Apple": 28, "Banana": 25, "Carrot Sticks": 30, "Salad": 32, "Water": 22,
	"Spinach Wrap": 29, "Berry Cup": 27, "Avocado Toast": 26, "Bean Bowl": 31,
	"Greek Yogurt": 28, "Orange Slices": 24, "Hummus Plate": 30, "Cucumber Sticks": 23,
	"Chicken Salad": 33, "Fruit Smoothie": 26,
	"Granola Bar": 16, "Juice Box": 14, "Crackers": 12, "Yogurt": 18, "Trail Mix": 15,
	"Protein Bar": 17, "Cheese Sticks": 14, "Pretzels": 11, "Bagel Bites": 13,
	"Cereal Cup": 15, "Flavored Milk": 14, "Fruit Gummies": 10, "Rice Cakes": 12,
	"Pita Chips": 11, "Snack Mix": 16,
	"Chips": 4, "Candy Bar": 3, "Soda": 2, "Cookies": 5, "Donut": 3, "Frosted Cake": 2,
	"Energy Soda": 2, "Caramel Pop": 4, "Chocolate Bites": 3, "Sugary Cereal": 4,
	"Iced Pastry": 3, "Cheese Puffs": 3, "Gummy Rope": 2, "Cream Cookie": 4, "Fizzy Punch": 2
}

func add_class_points(points: int) -> void:
	class_points += points

func add_convenience_ingredient(item_name: String, amount: int = 1) -> void:
	if item_name == "":
		return
	var add_amount: int = max(amount, 0)
	if add_amount <= 0:
		return
	if not convenience_inventory.has(item_name):
		convenience_inventory[item_name] = 0
	convenience_inventory[item_name] += add_amount

func get_convenience_inventory() -> Dictionary:
	return convenience_inventory.duplicate(true)

func consume_convenience_ingredient(item_name: String, amount: int = 1) -> bool:
	if item_name == "" or not convenience_inventory.has(item_name):
		return false
	var use_amount: int = max(amount, 0)
	if use_amount <= 0:
		return false
	var current: int = int(convenience_inventory[item_name])
	if current <= 0:
		return false
	current -= use_amount
	if current > 0:
		convenience_inventory[item_name] = current
	else:
		convenience_inventory.erase(item_name)
	_apply_food_effect(item_name)
	return true

func get_food_quality(item_name: String) -> String:
	return str(FOOD_QUALITY.get(item_name, "moderate"))


func food_quality_to_shelf_tier(quality: String) -> String:
	match quality:
		"natural":
			return "green"
		"moderate":
			return "yellow"
		_:
			return "red"


func estimate_nutrition_for_shop_item(item_name: String) -> int:
	if FOOD_NUTRITION.has(item_name):
		return int(FOOD_NUTRITION[item_name])
	match get_food_quality(item_name):
		"natural":
			return 26
		"moderate":
			return 14
		_:
			return 4


## Totals for shopkeeper UI from items added via add_convenience_ingredient (e.g. cardmain3 cart).
func get_convenience_inventory_shop_summary() -> Dictionary:
	var total_units := 0
	var total_nutrition := 0
	var green_units := 0
	var yellow_units := 0
	var red_units := 0
	for item_name in convenience_inventory.keys():
		var count: int = maxi(0, int(convenience_inventory[item_name]))
		if count <= 0:
			continue
		total_units += count
		var n: int = estimate_nutrition_for_shop_item(str(item_name))
		total_nutrition += n * count
		match food_quality_to_shelf_tier(get_food_quality(str(item_name))):
			"green":
				green_units += count
			"yellow":
				yellow_units += count
			_:
				red_units += count
	return {
		"total_units": total_units,
		"total_nutrition": total_nutrition,
		"green_units": green_units,
		"yellow_units": yellow_units,
		"red_units": red_units
	}


func get_player_speed_multiplier() -> float:
	return nutrition_speed_multiplier

func _apply_food_effect(item_name: String) -> void:
	var quality := get_food_quality(item_name)
	var pl: Node = pillars()
	match quality:
		"natural":
			nutrition_energy_score += 0.7
			if pl != null and pl.has_method("add_xp"):
				pl.add_xp("nutrition", randi_range(5, 9), "food_natural")
				pl.add_xp("wellbeing", randi_range(2, 4), "food_natural_wellbeing")
		"moderate":
			nutrition_energy_score += 0.2
			if pl != null and pl.has_method("add_xp"):
				pl.add_xp("nutrition", randi_range(2, 5), "food_moderate")
		_:
			nutrition_energy_score -= 0.9
			if pl != null and pl.has_method("add_xp"):
				pl.add_xp("sleep", randi_range(0, 2), "food_bad_crash")
	# Clamp and convert into movement impact. Lots of junk makes movement sluggish.
	nutrition_energy_score = clampf(nutrition_energy_score, -6.0, 6.0)
	nutrition_speed_multiplier = clampf(1.0 + nutrition_energy_score * 0.05, 0.7, 1.25)

func day_flow() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("DayFlow")

func pillars() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Pillars")
