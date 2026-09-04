extends Node2D

@onready var exit_button: Button = $UI/ExitButton

var normal_scale := Vector2(1.0, 1.0)
var hover_scale := Vector2(1.15, 1.15)
var pressed_scale := Vector2(1.08, 1.08)

var scale_tween: Tween


func _ready():
	exit_button.pressed.connect(_on_exit_button_pressed)

	exit_button.mouse_entered.connect(_on_exit_button_mouse_entered)
	exit_button.mouse_exited.connect(_on_exit_button_mouse_exited)
	exit_button.button_down.connect(_on_exit_button_button_down)
	exit_button.button_up.connect(_on_exit_button_button_up)

	exit_button.pivot_offset = exit_button.size / 2.0


func _on_exit_button_mouse_entered():
	_scale_button(hover_scale)


func _on_exit_button_mouse_exited():
	_scale_button(normal_scale)


func _on_exit_button_button_down():
	_scale_button(pressed_scale)


func _on_exit_button_button_up():
	_scale_button(hover_scale)


func _scale_button(new_scale: Vector2):
	if scale_tween:
		scale_tween.kill()

	scale_tween = create_tween()
	scale_tween.tween_property(
		exit_button,
		"scale",
		new_scale,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_exit_button_pressed():
	print("EXIT BUTTON PRESSED")
	SceneManager.return_to_previous_scene()
