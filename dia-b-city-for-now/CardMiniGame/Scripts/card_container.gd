extends HBoxContainer

var startPosition 
var MaxCardsAllowed = 6

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.size.x = MaxCardsAllowed*105
	self.pivot_offset.x = MaxCardsAllowed
	var projectResolutionWidth = ProjectSettings.get_setting("display/window/size/viewport_width")
	var projectResolutionHeight = ProjectSettings.get_setting("display/window/size/viewport_height")
	self.global_position.x = projectResolutionWidth/4
	self.global_position.y = (projectResolutionHeight) - 60
	startPosition = self.position
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	var target_position = startPosition + Vector2(0, -100)
	var tween = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	tween.tween_property(self, "position", target_position, 0.2)
	tween2.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)

func _on_mouse_exited() -> void:
	print("hola")
	if CardGame.card_Selected: 
		var tween = get_tree().create_tween()
		var tween2 = get_tree().create_tween()
		tween.tween_property(self, "position", startPosition, 0.2)
		tween2.tween_property(self, "scale", Vector2(1,1), 0.2)
