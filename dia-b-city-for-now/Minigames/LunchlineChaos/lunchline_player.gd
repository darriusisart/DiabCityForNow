extends CharacterBody2D

@export var move_speed: float = 750.0
@export var acceleration: float = 2500.0
@export var deceleration: float = 2500.0

@export var left_limit: float = 280.0
@export var right_limit: float = 1630.0

var game_over := false


func _ready():
	$CatchArea.area_entered.connect(_on_catch_area_body_entered)

func _physics_process(delta):
	# Stop movement when the game is over
	if game_over:
		velocity.x = 0.0
		velocity.y = 0.0
		return

	var direction = Input.get_axis("Left", "Right")

	if direction != 0:
		velocity.x = move_toward(
			velocity.x,
			direction * move_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			deceleration * delta
		)

	velocity.y = 0.0

	move_and_slide()

	position.x = clamp(position.x, left_limit, right_limit)


func _on_catch_area_body_entered(body):
	if body.is_in_group("food"):
		print("ON TRAY!")
