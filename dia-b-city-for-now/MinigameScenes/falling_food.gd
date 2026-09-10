extends Area2D

@export var fall_speed: float = 250.0

var shape_type: int = 0
var size: float = 40.0

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	randomize_shape()

func _process(delta):
	position.y += fall_speed * delta

	if position.y > 1200:
		queue_free()

func randomize_shape():
	shape_type = randi_range(0, 2)
	size = randf_range(25.0, 70.0)

	polygon.color = Color(
		randf_range(0.2, 1.0),
		randf_range(0.2, 1.0),
		randf_range(0.2, 1.0)
	)

	match shape_type:
		0:
			make_square()
		1:
			make_triangle()
		2:
			make_circle()

func make_square():
	var half = size / 2.0

	polygon.polygon = PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half)
	])

	var rect = RectangleShape2D.new()
	rect.size = Vector2(size, size)
	collision.shape = rect

func make_triangle():
	var half = size / 2.0

	polygon.polygon = PackedVector2Array([
		Vector2(0, -half),
		Vector2(half, half),
		Vector2(-half, half)
	])

	var circle = CircleShape2D.new()
	circle.radius = half
	collision.shape = circle

func make_circle():
	var points := PackedVector2Array()
	var point_count := 20

	for i in range(point_count):
		var angle = TAU * float(i) / point_count
		points.append(
			Vector2(
				cos(angle),
				sin(angle)
			) * size / 2.0
		)

	polygon.polygon = points

	var circle = CircleShape2D.new()
	circle.radius = size / 2.0
	collision.shape = circle
