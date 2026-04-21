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

const FOOD_QUALITY := {
	"Apple": "natural",
	"Banana": "natural",
	"Salad": "natural",
	"Carrot Sticks": "natural",
	"Water": "natural",
	"Granola Bar": "moderate",
	"Juice Box": "moderate",
	"Crackers": "moderate",
	"Yogurt": "moderate",
	"Trail Mix": "moderate",
	"Chips": "bad",
	"Candy Bar": "bad",
	"Soda": "bad",
	"Cookies": "bad",
	"Donut": "bad"
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

const PLAYER_SKINS = {
	Enums.Style.BASIC: preload("res://PlaceholderGraphics/characters/main/main_basic.png"),
	Enums.Style.BASEBALL: preload("res://PlaceholderGraphics/characters/main/main_blue.png"),
	Enums.Style.COWBOY: preload("res://PlaceholderGraphics/characters/main/main_cowboy.png"),
	Enums.Style.ENGLISH: preload("res://PlaceholderGraphics/characters/main/main_grey.png"),
	Enums.Style.STRAW: preload("res://PlaceholderGraphics/characters/main/main_straw.png"),
	Enums.Style.BEANIE: preload("res://PlaceholderGraphics/characters/main/main_red.png")}
const TILE_SIZE = 16
const PLANT_DATA = {
	Enums.Seed.TOMATO: {
		'texture': "res://graphics/plants/tomato.png",
		'icon_texture': "res://graphics/icons/tomato.png",
		'name':'Tomato',
		'h_frames': 3,
		'grow_speed': 0.6,
		'death_max': 3,
		'reward': Enums.Item.TOMATO},
	Enums.Seed.CORN: {
		'texture': "res://graphics/plants/corn.png",
		'icon_texture': "res://graphics/icons/corn.png",
		'name':'Corn',
		'h_frames': 3,
		'grow_speed': 1.0,
		'death_max': 2,
		'reward': Enums.Item.CORN},
	Enums.Seed.PUMPKIN: {
		'texture': "res://graphics/plants/pumpkin.png",
		'icon_texture': "res://graphics/icons/pumpkin.png",
		'name':'Pumpkin',
		'h_frames': 3,
		'grow_speed': 0.3,
		'death_max': 3,
		'reward': Enums.Item.PUMPKIN},
	Enums.Seed.WHEAT: {
		'texture': "res://graphics/plants/wheat.png",
		'icon_texture': "res://graphics/icons/wheat.png",
		'name':'Wheat',
		'h_frames': 3,
		'grow_speed': 1.0,
		'death_max': 3,
		'reward': Enums.Item.WHEAT}}
const MACHINE_UPGRADE_COST = {
	Enums.Machine.SPRINKLER: {
		'name': 'Sprinkler',
		'cost' :{Enums.Item.TOMATO: 30, Enums.Item.WHEAT: 20},
		'icon': preload("res://PlaceholderGraphics/icons/sprinkler.png"),
		'color': Color.SEA_GREEN},
	Enums.Machine.FISHER: {
		'name': 'Fisher',
		'cost' :{Enums.Item.WOOD: 25, Enums.Item.FISH: 15},
		'icon': preload("res://PlaceholderGraphics/icons/fisher.png"),
		'color': Color.SLATE_GRAY},
	Enums.Machine.SCARECROW: {
		'name': 'Scarecrow',
		'cost' : {Enums.Item.PUMPKIN: 15, Enums.Item.CORN: 15},
		'icon': preload("res://PlaceholderGraphics/icons/scarecrow.png"),
		'color': Color.BURLYWOOD}}
const HOUSE_COST = {
	1: {Enums.Item.WOOD: 30, Enums.Item.APPLE: 20},
	2: {Enums.Item.WOOD: 40, Enums.Item.APPLE: 30}}
const STYLE_UPGRADES = {
	Enums.Style.COWBOY: {
		'name': 'Cowboy',
		'cost':{Enums.Item.WOOD: 8, Enums.Item.CORN: 6},
		'icon': preload("res://PlaceholderGraphics/icons/cowboy.png"),
		'color': Color.SANDY_BROWN},
	Enums.Style.ENGLISH: {
		'name': 'Oldie',
		'cost':{Enums.Item.CORN: 8, Enums.Item.WHEAT: 6},
		'icon': preload("res://PlaceholderGraphics/icons/english.png"),
		'color': Color.LIGHT_GRAY},
	Enums.Style.BASEBALL: {
		'name': 'Baseball',
		'cost':{Enums.Item.TOMATO: 8, Enums.Item.APPLE: 6},
		'icon': preload("res://PlaceholderGraphics/icons/blue.png"),
		'color': Color.SKY_BLUE},
	Enums.Style.BEANIE: {
		'name': 'Beanie',
		'cost':{Enums.Item.PUMPKIN: 8, Enums.Item.WHEAT: 6},
		'icon': preload("res://PlaceholderGraphics/icons/beanie.png"),
		'color': Color.INDIAN_RED},
	Enums.Style.STRAW: {
		'name': 'Straw',
		'cost':{Enums.Item.FISH: 8, Enums.Item.WOOD: 6},
		'icon': preload("res://PlaceholderGraphics/icons/straw.png"),
		'color': Color.BURLYWOOD}}
const TOOL_STATE_ANIMATIONS = {
	Enums.Tool.HOE: 'Hoe',
	Enums.Tool.AXE: 'Axe',
	Enums.Tool.WATER: 'Water',
	Enums.Tool.SWORD: 'Sword',
	Enums.Tool.FISH: 'Fish',
	Enums.Tool.SEED: 'Seed',
	}
