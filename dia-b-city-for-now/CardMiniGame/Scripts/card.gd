extends Container

@onready var cardTemp = preload("res://CardMiniGame/CardHolder.tscn")
var StartPosition 
var CardHighlighted = false

func _on_mouse_entered() -> void:
	$Anim.play("Select")
	CardHighlighted = true

func _on_mouse_exited() -> void:
	$Anim.play("Deselect")
	CardHighlighted = false

#input for this specific instance only 
func _on_gui_input(event: InputEvent) -> void:
	#print(event)
	if (event is InputEventMouseButton) and (event.button_index == 1):
		
		if event.button_mask == 1:
			#button mask 1 = press down
			print("mouse down")
			if CardHighlighted:
				var cardTemp = cardTemp.instantiate()
				get_tree().get_root().get_node("Board/CardHolder").add_child(cardTemp)
				CardGame.card_Selected = true
				if CardHighlighted:
					#the get child 0 makes it so that the cards to consume the empty space until later
					self.get_child(0)#.hide()
		elif event.button_mask == 0:
			print("mouse up")
			#button mask 0 = press up
			if !CardGame.MouseOnPlacement:
				#Place Card NOT on Board
				CardHighlighted = false
				self.get_child(0)#.show()
			else: 
				#place Card On Board
				self.queue_free()
				get_node("../../CardPlacement").placeCard()
			for i in get_tree().get_root().get_node("Board/CardHolder").get_child_count():
				#only works if all cards are the same, change later when we expand it 
				get_tree().get_root().get_node("Board/CardHolder").get_child(i).queue_free()
			CardGame.card_Selected = false
