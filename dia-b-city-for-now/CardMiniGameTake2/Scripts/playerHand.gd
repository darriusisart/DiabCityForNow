extends Node2D

const HandCount = 12
const CardScenePath = "res://CardMiniGameTake2/Scenes/card.tscn"
const CardWidth = 200
const HandYPosition = 890


var player_hand = []
var center_screen_x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	var card_scene = preload(CardScenePath)
	for i in range(HandCount):
		var new_card = card_scene.instantiate()
		$"../CardManager".add_child(new_card)
		new_card.name = "Card"
		add_card_to_hand(new_card)


func add_card_to_hand(card):
	player_hand.insert(0, card)
	update_hand_positions()

func update_hand_positions():
	for i in range(player_hand.size()):
		#set new card position based on index passed on it 
		var new_position = Vector2(calculate_card_position(i), HandYPosition)
		var card = player_hand[i]
		animate_card_to_position(card, new_position)

func calculate_card_position(index):
	var total_width = (player_hand.size() -1) * CardWidth
	var x_offset = center_screen_x * index / (HandCount * 2)
	return x_offset

func animate_card_to_position(card, new_position):
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", new_position, 0.1)
