extends Node3D

@export var aisle_name := "1"
@export_enum("green", "yellow", "red") var difficulty := "yellow"
@export var manager_path: NodePath = NodePath("../..")

func interact(_player: Node) -> void:
	var manager := get_node_or_null(manager_path)
	if manager != null and manager.has_method("interact_with_aisle"):
		manager.interact_with_aisle(aisle_name, difficulty)
