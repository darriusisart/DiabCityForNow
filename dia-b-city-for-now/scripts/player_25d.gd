extends CharacterBody3D

const SPEED := 5.0

#var gravity := ProjectSettings.get_setting("physics/3d/default_gravity")
var current_input_dir := Vector2.ZERO
var portal_locked := false
var ui_locked := false
var active_interactable: Node = null

@onready var fade: ColorRect = $fade
@onready var prompt_panel: PanelContainer = $InteractUI/PromptPanel
@onready var prompt_label: Label = $InteractUI/PromptPanel/PromptLabel
@onready var sprite_3d: Sprite3D = $SpriteRoot/Sprite3D

var _walk_time := 0.0

func lock_direction() -> void:
	portal_locked = true

func set_ui_locked(locked: bool) -> void:
	ui_locked = locked
	if ui_locked:
		current_input_dir = Vector2.ZERO
		velocity.x = 0.0
		velocity.z = 0.0

func set_interactable(interactable: Node, prompt_text: String = "Press E to interact") -> void:
	active_interactable = interactable
	prompt_label.text = prompt_text
	prompt_panel.visible = true

func clear_interactable(interactable: Node) -> void:
	if active_interactable != interactable:
		return
	active_interactable = null
	prompt_panel.visible = false

func _physics_process(delta: float) -> void:
#	if not is_on_floor():
#		velocity.y -= gravity * delta

	if not portal_locked and not ui_locked:
		current_input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	elif ui_locked:
		current_input_dir = Vector2.ZERO

	var direction := (transform.basis * Vector3(current_input_dir.x, 0, current_input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_update_sprite_animation(delta)
	_handle_interaction_input()

func _update_sprite_animation(delta: float) -> void:
	var move_vec := Vector2(velocity.x, velocity.z)
	var moving := move_vec.length() > 0.2
	var row := _get_facing_row(move_vec)
	var frame := row * 33
	if moving:
		_walk_time += delta * 8.0
		frame += 2 + int(_walk_time) % 4
	else:
		_walk_time = 0.0
		frame += 0
	sprite_3d.frame = frame

func _get_facing_row(move_vec: Vector2) -> int:
	if move_vec == Vector2.ZERO:
		return 0
	if absf(move_vec.x) > absf(move_vec.y):
		return 2 if move_vec.x > 0.0 else 1
	return 0 if move_vec.y > 0.0 else 3

func _handle_interaction_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		#print("Hi")
		return
	if active_interactable == null:
		print("Hey")
		return
	if active_interactable.has_method("interact"):
		print("Hello")
		active_interactable.interact(self)
