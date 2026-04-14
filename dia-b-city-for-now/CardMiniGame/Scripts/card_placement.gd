extends Control

@onready var card = preload("res://CardMiniGame/CardOnBoard.tscn") 


func _on_mouse_entered() -> void:
	CardGame.MouseOnPlacement = true


func _on_mouse_exited() -> void:
	CardGame.MouseOnPlacement = false

func placeCard():
	var cardTemp = card.instantiate()
	var projectResolutionWidth = ProjectSettings.get_setting("display/window/size/viewport_width")
	var projectResolutionHeight = ProjectSettings.get_setting("display/window/size/viewport_height")
	global_position = Vector2(projectResolutionWidth/2, projectResolutionHeight/2) - self.position
	add_child(cardTemp)
