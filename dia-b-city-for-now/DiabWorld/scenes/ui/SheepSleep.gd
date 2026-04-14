extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var inc: float = 1
	set_position(Vector2(inc,0))
	inc += 10
	print(position)
#	set_position(Vector2(inc,0))
