extends CharacterBody3D

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

@export var move_speed := 6.2
@export var acceleration := 14.0
@export var deceleration := 25.0
@export var jump_velocity := 7.5
@export var gravity := 21.0

var last_view := "front"

func _ready():
	play_anim("idle_front")

func _physics_process(delta):
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= gravity * delta

	move_and_slide()
	update_animation(input_dir)


func update_animation(input_dir: Vector2):
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	# View Direction & Animation are based on the player's input
	if input_dir.y < 0:
		last_view = "back"
	elif input_dir.y > 0:
		last_view = "front"
	elif input_dir.x != 0:
		last_view = "side"

	# I'm still using the side_jump since I don't have the jump animations 
	# yet for the other views
	if not is_on_floor():
		if velocity.y > 0:
			play_anim("jump_" + last_view)

		sprite.speed_scale = 1.0
		return

	if horizontal_speed < 0.15:
		play_anim("idle_" + last_view)
		sprite.speed_scale = 1.0
	else:
		play_anim("walk_" + last_view)
		sprite.speed_scale = clamp(horizontal_speed / move_speed, 0.4, 1.0)

	# Only flip the side view
	if last_view == "side":
		if input_dir.x < 0:
			sprite.flip_h = true
		elif input_dir.x > 0:
			sprite.flip_h = false
	else:
		sprite.flip_h = false


func play_anim(anim_name: String):
	if sprite.animation != anim_name:
		sprite.play(anim_name)
