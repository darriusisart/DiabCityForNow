extends RigidBody2D

signal food_locked(points: int)

var shape_type: int = 0
var size: float = 70.0

var settle_timer: float = 0.0
var settle_time: float = 0.2

var locked := false
var tray: AnimatableBody2D
var tray_offset := Vector2.ZERO

enum NutritionTier {
	GREEN,
	YELLOW,
	RED
}

var nutrition_tier: NutritionTier
var nutrition_points: int

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready():
	add_to_group("food")
	randomize_shape()

	# Allows to touch another physics body (like the tray)
	contact_monitor = true
	max_contacts_reported = 4
	
	# Calling for nutrition points and category
	add_to_group("food")
	randomize_shape()
	assign_nutrition()

	contact_monitor = true
	max_contacts_reported = 4


func _physics_process(delta):
	if locked:
		global_position = tray.global_position + tray_offset
		return

	# If we're touching something and have almost stopped moving...
	if get_contact_count() > 0:
		if linear_velocity.length() < 25.0 and abs(angular_velocity) < 0.5:
			settle_timer += delta

			if settle_timer >= settle_time:
				lock_food()
		else:
			settle_timer = 0.0
	else:
		settle_timer = 0.0
		
func lock_food():
	freeze = true
	locked = true

	tray = get_tree().current_scene.get_node("Player/Tray")

	tray_offset = global_position - tray.global_position
	
	food_locked.emit(nutrition_points)

#This is where we can designate how many points each type of food is worth
#Traffic light system!
func assign_nutrition():
	var roll = randi_range(0, 2)

	match roll:
		0:
			nutrition_tier = NutritionTier.GREEN
			nutrition_points = 3
			polygon.color = Color(0.3, 0.8, 0.3)

		1:
			nutrition_tier = NutritionTier.YELLOW
			nutrition_points = 1
			polygon.color = Color(0.95, 0.8, 0.2)

		2:
			nutrition_tier = NutritionTier.RED
			nutrition_points = -2
			polygon.color = Color(0.9, 0.25, 0.25)

# I'm going to change the shapes to actual graphics, this is for testing
func randomize_shape():
	shape_type = randi_range(0, 2)
	size = randf_range(50.0, 100.0)

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

	var triangle = ConvexPolygonShape2D.new()
	triangle.points = polygon.polygon
	collision.shape = triangle


func make_circle():
	var points := PackedVector2Array()
	var point_count := 20

	for i in range(point_count):
		var angle = TAU * float(i) / point_count
		points.append(
			Vector2(cos(angle), sin(angle)) * size / 2.0
		)

	polygon.polygon = points

	var circle = CircleShape2D.new()
	circle.radius = size / 2.0
	collision.shape = circle
