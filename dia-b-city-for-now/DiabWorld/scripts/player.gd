extends CharacterBody3D

# References to seperate Spine rigs for multiple views
@onready var side_view = $SideView
@onready var front_view = $FrontView
@onready var camera = get_viewport().get_camera_3d()

const SPEED = 6.0
const JUMP_VELOCITY = 4.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var current_input_dir = Vector2.ZERO
var input_locked = false

@onready var fade = $fade

func lock_direction():
	input_locked = true

func update_character_view():
	var move_direction = Vector3(velocity.x, 0, velocity.z).normalized()

	# don't switch when standing still
	if move_direction.length() < 0.1:
		return

	var camera_direction = (camera.global_position - global_position).normalized()

	var dot = move_direction.dot(camera_direction)

	# facing camera
	if dot > 0.5:
		front_view.visible = true
		side_view.visible = false
	else:
		front_view.visible = false
		side_view.visible = true

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if !input_locked:
		current_input_dir = input_dir
		
	var direction = (transform.basis * Vector3(current_input_dir.x, 0, current_input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	update_character_view()
