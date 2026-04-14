extends Node3D

@export_file("*.tscn") var scene_path := "res://DiabWorld/scenes/Classroom.tscn"
@export var required_step_id := ""
@export var complete_step_on_enter := ""
@export var reward_pillar := ""
@export var reward_amount := 0
@export var bypass_day_flow_requirement := false
@export var catch_up_day_flow_to := ""
@export var play_school_bus_cutscene := false
@export_file("*.jpg") var school_bus_image_path := "res://DiabWorld/scenes/video/SchoolBus.jpg"
@export var bus_cutscene_seconds := 3.0
@export var day_flow_step_on_enter := ""
@export_file("*.tscn") var bus_spine_scene_path := "res://DiabWorld/splineplayer/newestspine/spineplayer.tscn"
@export var bus_spine_animation := "DarkMale_IdleAnimation"

func interact(_player: Node) -> void:
	var df: Node = Data.day_flow()
	if not bypass_day_flow_requirement and required_step_id != "" and df != null and df.has_method("can_enter"):
		if not df.can_enter(required_step_id):
			return
	if catch_up_day_flow_to != "" and df != null and df.has_method("catch_up_to"):
		df.catch_up_to(catch_up_day_flow_to)
	if complete_step_on_enter != "" and df != null and df.has_method("complete_step"):
		df.complete_step(complete_step_on_enter)
	if day_flow_step_on_enter != "" and df != null and df.has_method("complete_step"):
		df.complete_step(day_flow_step_on_enter)
	if df != null and df.has_method("note_next_location_from_scene_path"):
		df.note_next_location_from_scene_path(scene_path)
	var pl: Node = Data.pillars()
	if reward_pillar != "" and reward_amount > 0 and pl != null and pl.has_method("add_xp"):
		pl.add_xp(reward_pillar, reward_amount, "door_enter")
	if play_school_bus_cutscene:
		await _play_bus_cutscene(_player)
	get_tree().change_scene_to_file(scene_path)

func _play_bus_cutscene(player: Node) -> void:
	if player != null and player.has_method("set_ui_locked"):
		player.set_ui_locked(true)

	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)

	var bus := TextureRect.new()
	bus.set_anchors_preset(Control.PRESET_FULL_RECT)
	bus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bus_tex := load(school_bus_image_path)
	if bus_tex is Texture2D:
		bus.texture = bus_tex
	layer.add_child(bus)

	if not _add_spine_cutscene_character(layer):
		var player_tex := TextureRect.new()
		player_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		player_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		player_tex.custom_minimum_size = Vector2(260, 260)
		player_tex.position = Vector2(800, 360)
		_assign_player_texture(player, player_tex)
		layer.add_child(player_tex)

	var fade := ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	layer.add_child(fade)

	await get_tree().create_timer(maxf(0.1, bus_cutscene_seconds)).timeout
	var tw := create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 1), 0.6)
	await tw.finished

func _assign_player_texture(player: Node, target: TextureRect) -> void:
	if player == null:
		return
	var sprite := player.get_node_or_null("SpriteRoot/Sprite3D")
	if sprite == null or sprite.texture == null:
		return
	var tex: Texture2D = sprite.texture
	var hframes := int(sprite.hframes)
	var vframes := int(sprite.vframes)
	if hframes <= 1 or vframes <= 1:
		target.texture = tex
		return
	var frame := int(sprite.frame)
	var frame_w := int(tex.get_width() / hframes)
	var frame_h := int(tex.get_height() / vframes)
	if frame_w <= 0 or frame_h <= 0:
		target.texture = tex
		return
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2((frame % hframes) * frame_w, int(frame / hframes) * frame_h, frame_w, frame_h)
	target.texture = at

func _add_spine_cutscene_character(layer: CanvasLayer) -> bool:
	if bus_spine_scene_path == "":
		return false
	var scene_res := load(bus_spine_scene_path)
	if not (scene_res is PackedScene):
		return false
	var inst := (scene_res as PackedScene).instantiate()
	if not (inst is CanvasItem):
		if inst != null:
			inst.queue_free()
		return false
	var canvas := inst as CanvasItem
	layer.add_child(canvas)
	if canvas is Node2D:
		var n2d := canvas as Node2D
		n2d.position = Vector2(900, 640)
		n2d.scale = Vector2(0.22, 0.22)
	if bus_spine_animation != "":
		if canvas.has_method("set_animation"):
			var argc := _method_arg_count(canvas, "set_animation")
			if argc >= 3:
				canvas.call("set_animation", 0, bus_spine_animation, true)
			elif argc == 2:
				canvas.call("set_animation", bus_spine_animation, true)
			else:
				canvas.call("set_animation", bus_spine_animation)
		elif _has_property(canvas, "preview_animation"):
			canvas.set("preview_animation", bus_spine_animation)
	return true

func _has_property(target: Object, property_name: String) -> bool:
	for prop_info in target.get_property_list():
		if str(prop_info.get("name", "")) == property_name:
			return true
	return false

func _method_arg_count(target: Object, method_name: String) -> int:
	for method_info in target.get_method_list():
		if str(method_info.get("name", "")) == method_name:
			return int(method_info.get("args", []).size())
	return -1
