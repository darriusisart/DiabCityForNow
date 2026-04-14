extends Node3D

@export var controller_path: NodePath

func interact(_player: Node) -> void:
	var ctrl: Node = get_node_or_null(controller_path)
	if ctrl == null or not ctrl.has_method("add_clump_from_mound"):
		return
	var result: String = ctrl.add_clump_from_mound()
	var pl: Node = Data.pillars()
	if result == "merged" and pl != null and pl.has_method("add_xp"):
		pl.add_xp("nutrition", 6, "recess_suika_merge")
	elif pl != null and pl.has_method("add_xp"):
		pl.add_xp("exercise", 2, "recess_suika_dig")
