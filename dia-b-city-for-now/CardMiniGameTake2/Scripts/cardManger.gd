extends Node2D

const CollisionMaskCard = 1
const CollisionMaskCardSlot = 2

var screen_size
var card_being_dragged
var is_hovering_on_card

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("Clicked!")
			var card = raycast_check_for_card()
			if card: 
				start_drag(card)
		else:
			if card_being_dragged:
				finish_drag()
				print("Released!")

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))


func start_drag(card):
	#when card dragged the highlight is turned off
	card_being_dragged = card
	card.scale = Vector2(1.0, 1.0)

func finish_drag():
	#when card is let go, highlight is turned back on
	card_being_dragged.scale = Vector2(1.05, 1.05)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		#Card dropped in empty card slot
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
	card_being_dragged = null


func raycast_check_for_card():
	#checks to see if you clicked on a card
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = CollisionMaskCard
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#get the actual card not the area2d
		#print(result[0].collider.get_parent())
		
		#gets the highest card that actaully is at the top
		print(get_card_with_highest_z_index(result))
		return get_card_with_highest_z_index(result)
	print(result)
	return null

func raycast_check_for_card_slot():
	#checks to see if you clicked on a card
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = CollisionMaskCardSlot
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#get the actual card not the area2d
		#print(result[0].collider.get_parent())
		
		#gets the highest card that actaully is at the top
		print(result[0].collider.get_parent())
		return result[0].collider.get_parent()
	print(result)
	return null


func get_card_with_highest_z_index(cards):
	#so it always drags the card on top
	#assume the first card in cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	#loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card



func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	#if card is not already being dragged and not hovered over,
	#highlight card
	if !card_being_dragged and !is_hovering_on_card:
		print("hovered")
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	#if card is not already being dragged, and not hovered
	#unhighlight the card
	if !card_being_dragged:
		print("hovered_off")
		highlight_card(card, false)
		#check if hovered off card to another card immediately
		#so that it always hovers over the card on top
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false 

func highlight_card(card, hovered):
	if hovered:
		#scale it up and bring it higher up in the z index(so it shows infront)
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1.0, 1.0)
		card.z_index = 1
