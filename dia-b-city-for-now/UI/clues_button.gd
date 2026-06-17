extends TextureButton

@export var hover_scale := 1.06
@export var pressed_scale := 0.98
@export var tween_time := 0.08

var tween: Tween

func _ready():
	pivot_offset = size / 2

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _animate_scale(target_scale: Vector2):
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "scale", target_scale, tween_time)

func _on_mouse_entered():
	_animate_scale(Vector2.ONE * hover_scale)

func _on_mouse_exited():
	_animate_scale(Vector2.ONE)

func _on_button_down():
	_animate_scale(Vector2.ONE * pressed_scale)

func _on_button_up():
	_animate_scale(Vector2.ONE * hover_scale)
