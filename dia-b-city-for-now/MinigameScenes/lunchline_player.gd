extends CharacterBody2D

@export var move_speed: float = 600.0

func _physics_process(_delta):
	var direction = Input.get_axis("Left", "Right")

	velocity.x = direction * move_speed
	velocity.y = 0

	move_and_slide()
