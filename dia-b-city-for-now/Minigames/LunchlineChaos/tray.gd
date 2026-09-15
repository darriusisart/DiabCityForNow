extends AnimatableBody2D

@export var player: CharacterBody2D

func _physics_process(_delta):
	if player:
		global_position = player.global_position
