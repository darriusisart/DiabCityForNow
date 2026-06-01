extends Node3D

@onready var area = $Area3D
@onready var label = $Label3D

var player_in_range = false

func _ready():
	label.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		label.visible = true

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		label.visible = false
