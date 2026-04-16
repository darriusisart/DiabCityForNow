extends CharacterBody3D

const SPEED := 5.0
@export var use_spine_character := true
@export var spine_node_path: NodePath = NodePath("SpriteRoot/SpineRoot/SpinePlayer")
@export var spine_idle_animation := "DarkMale_IdleAnimation"
@export var spine_walk_animation := "DarkMale_WalkAnimation"
@export var spine_jump_animation := "DarkMale_ShortJump"
@export var spine_jump_duration := 0.45
@export var spine_flip_horizontal := true
@export var keep_spine_scale_constant := true
@export var show_animation_debug_text := true

#var gravity := ProjectSettings.get_setting("physics/3d/default_gravity")
var current_input_dir := Vector2.ZERO
var portal_locked := false
var ui_locked := false
var active_interactable: Node = null

@onready var fade: ColorRect = $fade
@onready var prompt_panel: PanelContainer = $InteractUI/PromptPanel
@onready var prompt_label: Label = $InteractUI/PromptPanel/PromptLabel
@onready var anim_debug_label: Label = get_node_or_null("InteractUI/AnimDebugLabel")
@onready var sprite_3d: Sprite3D = $SpriteRoot/Sprite3D

var _walk_time := 0.0
var _spine_visual: Node = null
var _using_spine := false
var _last_spine_anim := ""
var _spine_is_2d := false
var _spine_flip_sign := 1.0
var _spine_base_scale_2d := Vector2.ONE
var _spine_ref_distance := 1.0
var _jump_anim_end_msec: int = 0
var _stretch_session_active := false
var _stretch_anim_name := ""
var _last_debug_anim_text := ""

func _ready() -> void:
	add_to_group("player_avatar")
	_try_bind_spine_visual()
	_update_animation_debug_text("init")

func lock_direction() -> void:
	portal_locked = true

func set_ui_locked(locked: bool) -> void:
	ui_locked = locked
	if ui_locked:
		current_input_dir = Vector2.ZERO
		velocity.x = 0.0
		velocity.z = 0.0

func set_interactable(interactable: Node, prompt_text: String = "Press E to interact") -> void:
	active_interactable = interactable
	prompt_label.text = prompt_text
	prompt_panel.visible = true

func clear_interactable(interactable: Node) -> void:
	if active_interactable != interactable:
		return
	active_interactable = null
	prompt_panel.visible = false

func _physics_process(delta: float) -> void:
#	if not is_on_floor():
#		velocity.y -= gravity * delta
	if _can_process_jump_input() and Input.is_action_just_pressed("jump"):
		_trigger_jump_animation()

	if not portal_locked and not ui_locked:
		current_input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	elif ui_locked:
		current_input_dir = Vector2.ZERO

	var direction := (transform.basis * Vector3(current_input_dir.x, 0, current_input_dir.y)).normalized()
	var move_speed := _current_move_speed()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()
	_sync_spine_visual_position()
	_update_sprite_animation(delta)
	_handle_interaction_input()

func _update_sprite_animation(delta: float) -> void:
	if _using_spine:
		_update_spine_animation()
		return
	var move_vec := Vector2(velocity.x, velocity.z)
	var moving := move_vec.length() > 0.2
	var row := _get_facing_row(move_vec)
	var frame := row * 33
	if moving:
		_walk_time += delta * 8.0
		frame += 2 + int(_walk_time) % 4
	else:
		_walk_time = 0.0
		frame += 0
	sprite_3d.frame = frame
	_update_animation_debug_text("walk" if moving else "idle")

func _get_facing_row(move_vec: Vector2) -> int:
	if move_vec == Vector2.ZERO:
		return 0
	if absf(move_vec.x) > absf(move_vec.y):
		return 2 if move_vec.x > 0.0 else 1
	return 0 if move_vec.y > 0.0 else 3

func _update_spine_animation() -> void:
	if _spine_visual == null:
		return
	if _stretch_session_active:
		var loop_stretch := _stretch_anim_name.findn("jump") < 0
		_play_spine_animation(_stretch_anim_name, loop_stretch)
		return
	if _is_jump_anim_active():
		_play_spine_animation(spine_jump_animation, false)
		return
	var move_vec := Vector2(velocity.x, velocity.z)
	var moving := move_vec.length() > 0.2
	_update_spine_flip(move_vec)
	var anim_name := spine_idle_animation
	if moving:
		anim_name = spine_walk_animation
	_play_spine_animation(anim_name, true)

func _handle_interaction_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if active_interactable == null:
		return
	if active_interactable.has_method("interact"):
		active_interactable.interact(self)

func _try_bind_spine_visual() -> void:
	_using_spine = false
	_spine_visual = null
	_spine_is_2d = false
	if not use_spine_character:
		return
	var node := get_node_or_null(spine_node_path)
	if node == null:
		return
	var spine_class := node.get_class()
	var looks_like_spine := spine_class.findn("spine") >= 0 or _has_property(node, "skeleton_data_res") or _has_property(node, "preview_animation")
	if not looks_like_spine:
		return
	_spine_visual = node
	_using_spine = true
	_spine_is_2d = node is CanvasItem
	sprite_3d.visible = false
	if _spine_is_2d:
		var item := _spine_visual as CanvasItem
		_spine_base_scale_2d = item.scale
		var cam := get_viewport().get_camera_3d()
		if cam != null:
			_spine_ref_distance = maxf(0.1, cam.global_position.distance_to($SpriteRoot.global_transform.origin))
		else:
			_spine_ref_distance = 6.0
	_spine_flip_sign = 1.0
	_play_spine_animation(spine_idle_animation, true)

func _play_spine_animation(anim_name: String, loop: bool) -> bool:
	if _spine_visual == null:
		return false
	if anim_name == "":
		return false
	if _last_spine_anim == anim_name:
		return true
	var played := false
	var state = null
	if _spine_visual.has_method("get_animation_state"):
		state = _spine_visual.call("get_animation_state")
	if state != null and _set_state_animation_compat(state, anim_name, loop):
		played = true
	elif _spine_visual.has_method("set_animation"):
		var args := _method_arg_count(_spine_visual, "set_animation")
		if args >= 3:
			_spine_visual.call("set_animation", 0, anim_name, loop)
			played = true
		elif args == 2:
			_spine_visual.call("set_animation", anim_name, loop)
			played = true
		elif args == 1:
			_spine_visual.call("set_animation", anim_name)
			played = true
	elif _spine_visual.has_method("set_animation_by_name"):
		var args2 := _method_arg_count(_spine_visual, "set_animation_by_name")
		if args2 >= 3:
			_spine_visual.call("set_animation_by_name", 0, anim_name, loop)
			played = true
		elif args2 == 2:
			_spine_visual.call("set_animation_by_name", anim_name, loop)
			played = true
		elif args2 == 1:
			_spine_visual.call("set_animation_by_name", anim_name)
			played = true
	elif _spine_visual.has_method("setAnimation"):
		_spine_visual.call("setAnimation", 0, anim_name, loop)
		played = true
	elif _spine_visual.has_method("play"):
		_spine_visual.call("play", anim_name)
		played = true
	elif _has_property(_spine_visual, "preview_animation"):
		_spine_visual.set("preview_animation", anim_name)
		played = true

	if played:
		_force_node_loop(loop)
		_last_spine_anim = anim_name
		_update_animation_debug_text(anim_name)
	return played

func _update_animation_debug_text(anim_name: String) -> void:
	var text := "Anim: %s" % anim_name
	if anim_debug_label != null:
		anim_debug_label.visible = show_animation_debug_text
		if show_animation_debug_text:
			anim_debug_label.text = text
	if not show_animation_debug_text:
		return
	if text == _last_debug_anim_text:
		return
	_last_debug_anim_text = text
	print("[player_25d] ", text)

func _set_state_animation_compat(state: Object, anim_name: String, loop: bool) -> bool:
	if state.has_method("set_animation"):
		var argc := _method_arg_count(state, "set_animation")
		if argc <= 1:
			var entry0 = state.call("set_animation", anim_name)
			_force_state_loop(state, entry0, loop)
			return true
		if argc == 2:
			var entry1 = state.call("set_animation", anim_name, loop)
			_force_state_loop(state, entry1, loop)
			return true
		var entry2 = state.call("set_animation", anim_name, loop, 0)
		_force_state_loop(state, entry2, loop)
		return true
	if state.has_method("setAnimation"):
		var argc2 := _method_arg_count(state, "setAnimation")
		if argc2 <= 1:
			var entry3 = state.call("setAnimation", anim_name)
			_force_state_loop(state, entry3, loop)
			return true
		if argc2 == 2:
			var entry4 = state.call("setAnimation", anim_name, loop)
			_force_state_loop(state, entry4, loop)
			return true
		var entry5 = state.call("setAnimation", anim_name, loop, 0)
		_force_state_loop(state, entry5, loop)
		return true
	return false

func _force_state_loop(state: Object, entry: Variant, loop: bool) -> void:
	if state.has_method("set_track_loop"):
		state.call("set_track_loop", 0, loop)
	elif state.has_method("setTrackLoop"):
		state.call("setTrackLoop", 0, loop)
	if entry is Object:
		if _has_property(entry, "loop"):
			entry.set("loop", loop)
		elif _has_property(entry, "is_looping"):
			entry.set("is_looping", loop)

func _force_node_loop(loop: bool) -> void:
	if _spine_visual == null:
		return
	if _has_property(_spine_visual, "loop"):
		_spine_visual.set("loop", loop)
	elif _has_property(_spine_visual, "is_looping"):
		_spine_visual.set("is_looping", loop)

func _update_spine_flip(move_vec: Vector2) -> void:
	if not spine_flip_horizontal or _spine_visual == null:
		return
	if absf(move_vec.x) < 0.05:
		return
	_spine_flip_sign = -1.0 if move_vec.x < 0.0 else 1.0
	if _spine_visual is Node3D:
		var n3d := _spine_visual as Node3D
		var s3: Vector3 = n3d.scale
		s3.x = absf(s3.x) * _spine_flip_sign
		n3d.scale = s3

func _method_arg_count(target: Object, method_name: String) -> int:
	for method_info in target.get_method_list():
		if str(method_info.get("name", "")) == method_name:
			return int(method_info.get("args", []).size())
	return -1

func _has_property(target: Object, property_name: String) -> bool:
	for prop_info in target.get_property_list():
		if str(prop_info.get("name", "")) == property_name:
			return true
	return false

func _can_process_jump_input() -> bool:
	if portal_locked or ui_locked:
		return false
	var vp := get_viewport()
	if vp == null:
		return true
	var focus := vp.gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false
	return true

func _is_jump_anim_active() -> bool:
	return _jump_anim_end_msec > 0 and Time.get_ticks_msec() < _jump_anim_end_msec

func _trigger_jump_animation() -> void:
	if not _using_spine or _spine_visual == null:
		return
	if spine_jump_animation == "":
		return
	if _is_jump_anim_active():
		return
	var dur_ms := int(maxf(1.0, spine_jump_duration * 1750.0))
	_jump_anim_end_msec = Time.get_ticks_msec() + dur_ms
	_last_spine_anim = ""
	_play_spine_animation(spine_jump_animation, false)

func play_stretch_session(anim_name: String, duration_sec: float) -> void:
	if duration_sec <= 0.0:
		return
	set_ui_locked(true)
	var use_anim := anim_name
	if use_anim == "":
		use_anim = spine_jump_animation
	if not _using_spine:
		await get_tree().create_timer(duration_sec).timeout
		set_ui_locked(false)
		return
	_stretch_session_active = true
	_stretch_anim_name = use_anim
	var is_jump_style := use_anim.findn("jump") >= 0
	if is_jump_style:
		var jump_cycle_sec := maxf(spine_jump_duration, 0.95)
		var end_at := Time.get_ticks_msec() + int(duration_sec * 1000.0)
		while Time.get_ticks_msec() < end_at:
			_last_spine_anim = ""
			_play_spine_animation(use_anim, false)
			await get_tree().create_timer(jump_cycle_sec).timeout
	else:
		_last_spine_anim = ""
		_play_spine_animation(use_anim, true)
		await get_tree().create_timer(duration_sec).timeout
	if not is_instance_valid(self):
		return
	_stretch_session_active = false
	_stretch_anim_name = ""
	_last_spine_anim = ""
	_play_spine_animation(spine_idle_animation, true)
	set_ui_locked(false)

func _sync_spine_visual_position() -> void:
	if not _using_spine or _spine_visual == null:
		return
	if not _spine_is_2d:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var world_pos: Vector3 = $SpriteRoot.global_transform.origin
	if camera.is_position_behind(world_pos):
		if _spine_visual is CanvasItem:
			(_spine_visual as CanvasItem).visible = false
		return
	var screen_pos := camera.unproject_position(world_pos)
	if _spine_visual is CanvasItem:
		var item := _spine_visual as CanvasItem
		item.visible = true
		var factor := 1.0
		if not keep_spine_scale_constant:
			var dist := maxf(0.1, camera.global_position.distance_to(world_pos))
			factor = clampf(_spine_ref_distance / dist, 0.55, 1.8)
		item.scale = Vector2(
			absf(_spine_base_scale_2d.x) * _spine_flip_sign * factor,
			_spine_base_scale_2d.y * factor
		)
		if item.has_method("set_global_position"):
			item.call("set_global_position", screen_pos)
		elif item.has_method("set_position"):
			item.call("set_position", screen_pos)

func _current_move_speed() -> float:
	var speed_mult := 1.0
	if Data != null and Data.has_method("get_player_speed_multiplier"):
		speed_mult = float(Data.get_player_speed_multiplier())
	return SPEED * clampf(speed_mult, 0.65, 1.35)
