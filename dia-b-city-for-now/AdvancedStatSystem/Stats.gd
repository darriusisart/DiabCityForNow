extends Resource
class_name Stats

@export var max_health: int = 100
@export var defense: int = 10
@export var attack: int = 10 

var health: int = 0

func _init() -> void:
	setup_stats()

func setup_stats():
	health = max_health
	print(health)
