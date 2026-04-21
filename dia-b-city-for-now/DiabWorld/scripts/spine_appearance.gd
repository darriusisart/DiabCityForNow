extends RefCounted
class_name SpineAppearance
## Helpers for spine-godot: outfits (skins) and per-slot tint colors.
## Skins: use Spine skins per outfit, or mix-and-match via combined skins in Spine Editor.
## Colors: call set_slot_color() with slot names from your skeleton (see SpineSprite Debug inspector).

const IDLE_ANIM_FALLBACK := "DarkMale_IdleAnimation"

static func get_skeleton(spine_sprite: Node) -> Object:
	var target := _resolve_spine_node(spine_sprite)
	if target == null:
		return null
	if target.has_method("get_skeleton"):
		return target.get_skeleton()
	return null

static func list_skin_names(spine_sprite: Node) -> PackedStringArray:
	var names: PackedStringArray = []
	var skel: Object = get_skeleton(spine_sprite)
	if skel == null:
		return _fallback_skin_names(spine_sprite)
	var data: Object = null
	if skel.has_method("get_data"):
		data = skel.get_data()
	if data == null:
		return _fallback_skin_names(spine_sprite)
	if data.has_method("get_skins"):
		var skins = data.get_skins()
		if skins is Array:
			for s in skins:
				if s != null and s.has_method("get_name"):
					names.append(String(s.get_name()))
	if names.is_empty():
		return _fallback_skin_names(spine_sprite)
	return names

static func list_slot_names(spine_sprite: Node) -> PackedStringArray:
	var names: PackedStringArray = []
	var skel: Object = get_skeleton(spine_sprite)
	if skel == null:
		return names
	if not skel.has_method("get_data"):
		return names
	var data: Object = skel.get_data()
	if data == null or not data.has_method("get_slots"):
		return names
	var slots = data.get_slots()
	if slots is Array:
		for s in slots:
			if s != null and s.has_method("get_name"):
				names.append(String(s.get_name()))
	return names

static func _fallback_skin_names(spine_sprite: Node) -> PackedStringArray:
	var out: PackedStringArray = ["Default"]
	var target := _resolve_spine_node(spine_sprite)
	if target != null and _has_prop(target, "preview_skin"):
		var ps: Variant = target.get("preview_skin")
		if str(ps) != "":
			out = PackedStringArray([str(ps)])
	return out

static func apply_skin_by_name(spine_sprite: Node, skin_name: String) -> bool:
	if spine_sprite == null or skin_name == "":
		return false
	var target := _resolve_spine_node(spine_sprite)
	var skel: Object = get_skeleton(target)
	if skel == null:
		if target != null and _has_prop(target, "preview_skin"):
			target.set("preview_skin", skin_name)
			return true
		return false
	if skel.has_method("set_skin_by_name"):
		skel.call("set_skin_by_name", skin_name)
		if skel.has_method("set_slots_to_setup_pose"):
			skel.set_slots_to_setup_pose()
		return true
	var data: Object = null
	if skel.has_method("get_data"):
		data = skel.get_data()
	if data != null and data.has_method("find_skin"):
		var skin: Object = data.find_skin(skin_name)
		if skin != null and skel.has_method("set_skin"):
			skel.set_skin(skin)
			if skel.has_method("set_slots_to_setup_pose"):
				skel.set_slots_to_setup_pose()
			return true
	if target != null and _has_prop(target, "preview_skin"):
		target.set("preview_skin", skin_name)
		return true
	return false

static func set_slot_color(spine_sprite: Node, slot_name: String, tint: Color) -> bool:
	if spine_sprite == null or slot_name == "":
		return false
	var skel: Object = get_skeleton(spine_sprite)
	if skel == null or not skel.has_method("find_slot"):
		return false
	var slot: Object = skel.find_slot(slot_name)
	if slot == null:
		return false
	if slot.has_method("set_color"):
		slot.call("set_color", tint)
		return true
	if _has_prop(slot, "color"):
		slot.set("color", tint)
		return true
	return false

static func set_global_tint(spine_sprite: Node, tint: Color) -> bool:
	var target := _resolve_spine_node(spine_sprite)
	if target == null:
		return false
	if target is CanvasItem:
		(target as CanvasItem).modulate = tint
		return true
	if _has_prop(target, "modulate"):
		target.set("modulate", tint)
		return true
	if _has_prop(target, "self_modulate"):
		target.set("self_modulate", tint)
		return true
	return false

## Swap one body part by changing a slot attachment (e.g. Hair, Hat, Shirt).
## [param attachment_name] must exist in the current skin or resolved skin path.
static func set_slot_attachment(spine_sprite: Node, slot_name: String, attachment_name: String) -> bool:
	if spine_sprite == null or slot_name == "":
		return false
	var skel: Object = get_skeleton(spine_sprite)
	if skel == null:
		return false
	if skel.has_method("set_attachment"):
		skel.call("set_attachment", slot_name, attachment_name)
		return true
	var state: Object = null
	if spine_sprite.has_method("get_animation_state"):
		state = spine_sprite.call("get_animation_state")
	if state != null and state.has_method("set_attachment"):
		state.call("set_attachment", slot_name, attachment_name)
		return true
	return false

static func clear_slot_attachment(spine_sprite: Node, slot_name: String) -> bool:
	return set_slot_attachment(spine_sprite, slot_name, "")

## Convenience helper for part-driven customization.
## Example map: {"Hair": "hair_long_01", "Top": "hoodie_blue"}
static func apply_slot_attachment_map(spine_sprite: Node, slot_to_attachment: Dictionary) -> void:
	if spine_sprite == null:
		return
	for slot_name in slot_to_attachment.keys():
		var attachment_name := String(slot_to_attachment[slot_name]).strip_edges()
		set_slot_attachment(spine_sprite, String(slot_name), attachment_name)

static func play_idle(spine_sprite: Node, anim_name: String = "") -> void:
	var name := anim_name if anim_name != "" else IDLE_ANIM_FALLBACK
	var target := _resolve_spine_node(spine_sprite)
	if target == null:
		return
	if target.has_method("set_animation"):
		var argc := _method_arg_count(target, "set_animation")
		if argc >= 3:
			target.call("set_animation", 0, name, true)
			return
		if argc == 2:
			target.call("set_animation", name, true)
			return
		if argc == 1:
			target.call("set_animation", name)
			return
	if target.has_method("set_animation_by_name"):
		var argc2 := _method_arg_count(target, "set_animation_by_name")
		if argc2 >= 3:
			target.call("set_animation_by_name", 0, name, true)
			return
		if argc2 == 2:
			target.call("set_animation_by_name", name, true)
			return
		if argc2 == 1:
			target.call("set_animation_by_name", name)
			return
	if _has_prop(target, "preview_animation"):
		target.set("preview_animation", name)

static func apply_saved_appearance(spine_sprite: Node) -> void:
	if spine_sprite == null or Data == null:
		return
	var global_tint: Variant = Data.player_spine_global_tint
	if global_tint is Color:
		set_global_tint(spine_sprite, global_tint)
	var skin: String = Data.player_spine_skin
	if skin != "":
		apply_skin_by_name(spine_sprite, skin)
	var parts: Dictionary = Data.player_spine_part_attachments.duplicate(true)
	if not parts.is_empty():
		apply_slot_attachment_map(spine_sprite, parts)
	var tints: Dictionary = Data.player_spine_slot_tints.duplicate(true)
	for slot_name in tints.keys():
		var c: Variant = tints[slot_name]
		if c is Color:
			set_slot_color(spine_sprite, String(slot_name), c)
		elif c is Dictionary:
			var col := Color(
				float(c.get("r", 1.0)),
				float(c.get("g", 1.0)),
				float(c.get("b", 1.0)),
				float(c.get("a", 1.0))
			)
			set_slot_color(spine_sprite, String(slot_name), col)

static func _has_prop(o: Object, prop: String) -> bool:
	for d in o.get_property_list():
		if str(d.get("name", "")) == prop:
			return true
	return false

static func _method_arg_count(o: Object, method_name: String) -> int:
	for method_info in o.get_method_list():
		if str(method_info.get("name", "")) == method_name:
			return int(method_info.get("args", []).size())
	return -1

static func _resolve_spine_node(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_skeleton") or _has_prop(node, "skeleton_data_res"):
		return node
	for child in node.get_children():
		if child is Node:
			var c := child as Node
			if c.has_method("get_skeleton") or _has_prop(c, "skeleton_data_res"):
				return c
	return node
