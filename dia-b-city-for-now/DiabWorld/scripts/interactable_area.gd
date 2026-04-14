extends Area3D

@export var prompt_text := "Press E to interact"
@export var interact_target_path: NodePath = NodePath("..")

func _ready() -> void:
	collision_mask = 2
	monitoring = true

func _get_target() -> Node:
	if interact_target_path == NodePath(""):
		return get_parent()
	return get_node_or_null(interact_target_path)

func _on_body_entered(body: Node) -> void:
	var target := _get_target()
	if target == null:
		return
	if body.has_method("set_interactable"):
		body.set_interactable(target, prompt_text)

func _on_body_exited(body: Node) -> void:
	var target := _get_target()
	if target == null:
		return
	if body.has_method("clear_interactable"):
		body.clear_interactable(target)
