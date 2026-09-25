extends CharacterBody2D

@export var move_speed: float = 120.0
@export var direction_change_time: float = 1.0
@export var arena_radius: float = 350.0

@export var grab_radius: float = 50.0
@export var grab_strength: float = 18.0
@export var grab_damping: float = 8.0

var target_velocity := Vector2.ZERO
var direction_timer := 0.0

var is_outside_arena := false
var is_grabbed := false
var grab_offset := Vector2.ZERO


func _ready():
	randomize()


func _physics_process(delta):


	direction_timer -= delta

	if direction_timer <= 0.0:
		direction_timer = direction_change_time

		var random_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		target_velocity = random_direction * move_speed

	velocity = velocity.lerp(target_velocity, 2.0 * delta)

	handle_mouse_grab()

	if is_grabbed:
		apply_grab_force(delta)


	move_and_slide()


	check_arena_boundary()


func handle_mouse_grab():

	var mouse_position = get_global_mouse_position()
	var distance_to_mouse = global_position.distance_to(mouse_position)


	# Mouse button is currently being held
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

		# Start grabbing if we aren't already grabbing
		if not is_grabbed:

			if distance_to_mouse <= grab_radius:

				is_grabbed = true

				grab_offset = global_position - mouse_position

				print("ORB GRABBED")


	# Mouse button released
	else:

		if is_grabbed:
			is_grabbed = false
			print("ORB RELEASED")


func apply_grab_force(delta):

	var mouse_position = get_global_mouse_position()

	# Where the orb is trying to be relative to the mouse
	var target_position = mouse_position + grab_offset

	var difference = target_position - global_position

	# Pull the orb toward the mouse
	velocity += difference * grab_strength * delta

	velocity *= 1.0 - (grab_damping * delta)


func check_arena_boundary():

	var distance_from_center = position.length()

	if distance_from_center > arena_radius:

		if not is_outside_arena:

			is_outside_arena = true

			print("ORB LEFT ARENA!")

	else:

		if is_outside_arena:

			is_outside_arena = false

			print("ORB RETURNED TO ARENA")
