extends Camera3D

@export var speed := 10.0
@export var mouse_sensitivity := 0.003

var active := false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		active = !active
		current = active
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE

	if active and event is InputEventMouseMotion:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clamp(rotation.x, -1.4, 1.4)

func _process(delta):
	if not active:
		return

	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x
	if Input.is_key_pressed(KEY_E):
		direction += transform.basis.y
	if Input.is_key_pressed(KEY_Q):
		direction -= transform.basis.y

	if direction != Vector3.ZERO:
		position += direction.normalized() * speed * delta
