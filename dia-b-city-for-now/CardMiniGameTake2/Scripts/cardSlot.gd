extends Node2D

var card_in_slot = false
#var card_value: int = 1
var score: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print($Area2D.collision_mask)

func _input(event):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_in_slot:
		print("card here")
		var addedscore = randi() % 10
		score += addedscore
		print(score)
		card_in_slot = false
	else:
		pass
