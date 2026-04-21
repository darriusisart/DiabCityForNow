extends CharacterBody3D

const SPEED := 5.0
enum SpineAnimState { IDLE, WALK, JUMP, STRETCH }
const CUSTOM_ATLAS_PATH := ""
const CUSTOM_SKELETON_PATH := "res://DiabWorld/scenes/ui/pictures/player/MainCharacterSideViewPSD.json"
const CUSTOM_META_SKELETON_PATH := "res://DiabWorld/scenes/ui/pictures/player/skeleton.json"
@export var use_spine_character := true
@export var spine_node_path: NodePath = NodePath("SpriteRoot/SpineRoot/SpinePlayer")
@export var spine_idle_animation := "DarkMale_IdleAnimation"
@export var spine_walk_animation := "DarkMale_WalkAnimation"
@export var spine_jump_animation := "DarkMale_ShortJump"
@export var spine_jump_duration := 0.45
@export var spine_flip_horizontal := true
@export var keep_spine_scale_constant := true
# With ortho cameras, nudge Spine screen scale so character size stays stable if zoom (camera size) changes.
@export var compensate_orthographic_zoom := true

#var gravity := ProjectSettings.get_setting("physics/3d/default_gravity")
var current_input_dir := Vector2.ZERO
var portal_locked := false
var ui_locked := false
var active_interactable: Node = null

@onready var fade: ColorRect = $fade
@onready var prompt_panel: PanelContainer = $InteractUI/PromptPanel
@onready var prompt_label: Label = $InteractUI/PromptPanel/PromptLabel
@onready var sprite_3d: Sprite3D = $SpriteRoot/Sprite3D
var pause_menu: CanvasLayer = null

var _walk_time := 0.0
var _spine_visual: Node = null
var _using_spine := false
var _last_spine_anim := ""
var _spine_is_2d := false
var _spine_flip_sign := 1.0
var _spine_base_scale_2d := Vector2.ONE
var _spine_ref_distance := 1.0
# Wall-clock end (msec); 0 = jump overlay inactive. Avoids one physics frame eating the whole window when delta is large.
var _jump_anim_end_msec: int = 0
var _stretch_session_active := false
var _stretch_anim_name := ""
var _spine_ref_ortho_camera_size := -1.0
var _spine_state: SpineAnimState = SpineAnimState.IDLE
var _spine_state_entered_msec: int = 0

func _ready() -> void:
	pause_menu = get_node_or_null("PauseMenu") as CanvasLayer
	add_to_group("player_avatar")
	_try_bind_spine_visual()
	_try_apply_custom_sprite()

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
	var total_frames := sprite_3d.hframes * sprite_3d.vframes
	if total_frames < 132:
		sprite_3d.frame = 0
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

func _update_spine_animation() -> void:
	if _spine_visual == null:
		return
	var move_vec := Vector2(velocity.x, velocity.z)
	var desired := _determine_desired_spine_state(move_vec)
	if desired != _spine_state:
		_transition_spine_state(desired, move_vec)
		return
	if desired == SpineAnimState.WALK:
		_update_spine_flip(move_vec)

func _determine_desired_spine_state(move_vec: Vector2) -> SpineAnimState:
	if _stretch_session_active:
		return SpineAnimState.STRETCH
	if _is_jump_anim_active():
		return SpineAnimState.JUMP
	if move_vec.length() > 0.2:
		return SpineAnimState.WALK
	return SpineAnimState.IDLE

func _transition_spine_state(next_state: SpineAnimState, move_vec: Vector2 = Vector2.ZERO) -> void:
	_spine_state = next_state
	_spine_state_entered_msec = Time.get_ticks_msec()
	match next_state:
		SpineAnimState.STRETCH:
			var loop_stretch := _stretch_anim_name.findn("jump") < 0
			_last_spine_anim = ""
			_play_spine_animation(_stretch_anim_name, loop_stretch)
		SpineAnimState.JUMP:
			_last_spine_anim = ""
			_play_spine_animation(spine_jump_animation, false)
		SpineAnimState.WALK:
			_update_spine_flip(move_vec)
			_play_spine_animation(spine_walk_animation, true)
		SpineAnimState.IDLE:
			_play_spine_animation(spine_idle_animation, true)

func _get_facing_row(move_vec: Vector2) -> int:
	if move_vec == Vector2.ZERO:
		return 0
	if absf(move_vec.x) > absf(move_vec.y):
		return 2 if move_vec.x > 0.0 else 1
	return 0 if move_vec.y > 0.0 else 3

func _facing_suffix(move_vec: Vector2) -> String:
	if move_vec == Vector2.ZERO:
		return "down"
	if absf(move_vec.x) > absf(move_vec.y):
		return "right" if move_vec.x > 0.0 else "left"
	return "down" if move_vec.y > 0.0 else "up"

func _handle_interaction_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if active_interactable == null:
		return
	if active_interactable.has_method("interact"):
		active_interactable.interact(self)

func _try_apply_custom_sprite() -> void:
	if _using_spine:
		sprite_3d.visible = false
		return
	# The provided files are Spine export data. If the atlas can be loaded as a texture,
	# use it; otherwise keep the existing spritesheet without breaking movement animation.
	if CUSTOM_ATLAS_PATH != "":
		var custom_texture := load(CUSTOM_ATLAS_PATH)
		if custom_texture is Texture2D:
			sprite_3d.texture = custom_texture
			sprite_3d.hframes = 1
			sprite_3d.vframes = 1

	# Parse provided JSON files so we can validate they are available in this build.
	for file_path in [CUSTOM_SKELETON_PATH, CUSTOM_META_SKELETON_PATH]:
		if not FileAccess.file_exists(file_path):
			continue
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("Invalid character JSON: " + file_path)

func _try_bind_spine_visual() -> void:
	_using_spine = false
	_spine_visual = null
	_spine_is_2d = false
	if not use_spine_character:
		print("Player Spine: disabled by use_spine_character=false")
		return
	if spine_node_path == NodePath(""):
		print("Player Spine: spine_node_path is empty, using Sprite3D fallback")
		return
	var node := get_node_or_null(spine_node_path)
	if node == null:
		print("Player Spine: node not found at path ", String(spine_node_path), ", using Sprite3D fallback")
		return
	# Accept common Spine node signatures across runtime versions.
	var spine_class := node.get_class()
	var looks_like_spine := spine_class.findn("spine") >= 0 or _has_property(node, "skeleton_data_res") or _has_property(node, "preview_animation")
	if looks_like_spine:
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
		print("Player Spine: bound successfully to ", node.name, " (class=", spine_class, ", is_2d=", _spine_is_2d, ")")
		_print_spine_animation_capabilities(node)
		SpineAppearance.apply_saved_appearance(_spine_visual)
		_spine_state = SpineAnimState.IDLE
		_spine_state_entered_msec = Time.get_ticks_msec()
	else:
		print("Player Spine: node exists but has no supported animation API, using Sprite3D fallback")

func _play_spine_animation(anim_name: String, loop: bool) -> bool:
	if _spine_visual == null:
		return false
	if _last_spine_anim == anim_name:
		return true

	var played := false
	var play_path := ""
	var state = null
	if _spine_visual.has_method("get_animation_state"):
		state = _spine_visual.call("get_animation_state")
	if state != null:
		if _set_state_animation_compat(state, anim_name, loop):
			played = true
			play_path = "state.compat_set_animation"
	elif _spine_visual.has_method("set_animation"):
		var args := _method_arg_count(_spine_visual, "set_animation")
		if args >= 3:
			_spine_visual.call("set_animation", 0, anim_name, loop)
			played = true
			play_path = "node.set_animation(3)"
		elif args == 2:
			_spine_visual.call("set_animation", anim_name, loop)
			played = true
			play_path = "node.set_animation(2)"
		elif args == 1:
			_spine_visual.call("set_animation", anim_name)
			played = true
			play_path = "node.set_animation(1)"
	elif _spine_visual.has_method("set_animation_by_name"):
		var args2 := _method_arg_count(_spine_visual, "set_animation_by_name")
		if args2 >= 3:
			_spine_visual.call("set_animation_by_name", 0, anim_name, loop)
			played = true
			play_path = "node.set_animation_by_name(3)"
		elif args2 == 2:
			_spine_visual.call("set_animation_by_name", anim_name, loop)
			played = true
			play_path = "node.set_animation_by_name(2)"
		elif args2 == 1:
			_spine_visual.call("set_animation_by_name", anim_name)
			played = true
			play_path = "node.set_animation_by_name(1)"
	elif _spine_visual.has_method("setAnimation"):
		_spine_visual.call("setAnimation", 0, anim_name, loop)
		played = true
		play_path = "node.setAnimation"
	elif _spine_visual.has_method("play"):
		_spine_visual.call("play", anim_name)
		played = true
		play_path = "node.play"
	else:
		state = _spine_visual.get("animation_state")
		if state != null and state.has_method("set_animation"):
			state.call("set_animation", 0, anim_name, loop)
			played = true
			play_path = "prop.animation_state.set_animation"
		elif _has_property(_spine_visual, "animation"):
			_spine_visual.set("animation", anim_name)
			played = true
			play_path = "prop.animation"
		elif _has_property(_spine_visual, "animation_name"):
			_spine_visual.set("animation_name", anim_name)
			played = true
			play_path = "prop.animation_name"
		elif _has_property(_spine_visual, "current_animation"):
			_spine_visual.set("current_animation", anim_name)
			played = true
			play_path = "prop.current_animation"
		elif _has_property(_spine_visual, "preview_animation"):
			_spine_visual.set("preview_animation", anim_name)
			played = true
			play_path = "prop.preview_animation"

	if played:
		_force_node_loop(loop)
		_last_spine_anim = anim_name
		print("Player Spine: playing animation ", anim_name, " via ", play_path)
	else:
		push_warning("Player Spine: failed to play animation " + anim_name)
	return played

func _set_state_animation_compat(state: Object, anim_name: String, loop: bool) -> bool:
	# Spine runtime variants use different argument orders.
	if state.has_method("set_animation"):
		var argc := _method_arg_count(state, "set_animation")
		var arg_names := _method_arg_names(state, "set_animation")
		if argc <= 1:
			var entry0 = state.call("set_animation", anim_name)
			_force_state_loop(state, entry0, loop)
			return true
		if argc == 2:
			var entry1 = state.call("set_animation", anim_name, loop)
			_force_state_loop(state, entry1, loop)
			return true
		# Choose argument order by method metadata when available.
		var entry2 = null
		if arg_names.size() >= 3 and str(arg_names[1]).findn("track") >= 0:
			entry2 = state.call("set_animation", anim_name, 0, loop)
		elif arg_names.size() >= 3 and str(arg_names[2]).findn("track") >= 0:
			entry2 = state.call("set_animation", anim_name, loop, 0)
		else:
			# Most common Spine wrapper order in Godot builds.
			entry2 = state.call("set_animation", anim_name, loop, 0)
		_force_state_loop(state, entry2, loop)
		return true
	if state.has_method("setAnimation"):
		var argc2 := _method_arg_count(state, "setAnimation")
		var arg_names2 := _method_arg_names(state, "setAnimation")
		if argc2 <= 1:
			var entry3 = state.call("setAnimation", anim_name)
			_force_state_loop(state, entry3, loop)
			return true
		if argc2 == 2:
			var entry4 = state.call("setAnimation", anim_name, loop)
			_force_state_loop(state, entry4, loop)
			return true
		var entry5 = null
		if arg_names2.size() >= 3 and str(arg_names2[1]).findn("track") >= 0:
			entry5 = state.call("setAnimation", anim_name, 0, loop)
		elif arg_names2.size() >= 3 and str(arg_names2[2]).findn("track") >= 0:
			entry5 = state.call("setAnimation", anim_name, loop, 0)
		else:
			entry5 = state.call("setAnimation", anim_name, loop, 0)
		_force_state_loop(state, entry5, loop)
		return true
	return false

func _force_state_loop(state: Object, entry: Variant, loop: bool) -> void:
	# Some runtime builds ignore the loop flag in set_animation, so force it.
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

func _method_arg_names(target: Object, method_name: String) -> PackedStringArray:
	var names := PackedStringArray()
	for method_info in target.get_method_list():
		if str(method_info.get("name", "")) != method_name:
			continue
		for arg_info in method_info.get("args", []):
			names.append(str(arg_info.get("name", "")))
		return names
	return names

func _has_property(target: Object, property_name: String) -> bool:
	for prop_info in target.get_property_list():
		if str(prop_info.get("name", "")) == property_name:
			return true
	return false

func _print_spine_animation_capabilities(target: Object) -> void:
	var interesting := PackedStringArray()
	for method_info in target.get_method_list():
		var aniname := str(method_info.get("name", ""))
		if aniname.findn("anim") >= 0 or aniname.findn("play") >= 0:
			interesting.append(aniname)
	print("Player Spine: animation methods detected -> ", ", ".join(interesting))
	var prop_interesting := PackedStringArray()
	for prop_info in target.get_property_list():
		var pname := str(prop_info.get("name", ""))
		if pname.findn("anim") >= 0 or pname.findn("skeleton") >= 0:
			prop_interesting.append(pname)
	print("Player Spine: animation/skeleton properties -> ", ", ".join(prop_interesting))
	if target.has_method("get_animation_state"):
		var state = target.call("get_animation_state")
		if state != null and state is Object:
			var state_methods := PackedStringArray()
			for method_info in state.get_method_list():
				var mname := str(method_info.get("name", ""))
				if mname.findn("anim") >= 0 or mname.findn("track") >= 0 or mname.findn("set") >= 0:
					state_methods.append(mname)
			print("Player Spine: animation state methods -> ", ", ".join(state_methods))
		else:
			print("Player Spine: get_animation_state() returned null/non-object")

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
	# Lock jump retriggering until the current jump window fully ends.
	if _is_jump_anim_active():
		return
	var dur_ms := int(maxf(1.0, spine_jump_duration * 1750.0))
	_jump_anim_end_msec = Time.get_ticks_msec() + dur_ms
	# Force replay even if the previous animation name matches.
	_last_spine_anim = ""
	_spine_state = SpineAnimState.IDLE
	_play_spine_animation(spine_jump_animation, false)

# Looped stretch at home (tai chi / yoga). Uses [member spine_idle_animation] if Spine is off or [param anim_name] is empty.
func play_stretch_session(anim_name: String, duration_sec: float) -> void:
	if duration_sec <= 0.0:
		return
	set_ui_locked(true)
	var use_anim := anim_name
	if use_anim == "" or not _using_spine:
		use_anim = spine_idle_animation
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
			if compensate_orthographic_zoom and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				var sz := camera.size
				if _spine_ref_ortho_camera_size <= 0.0:
					_spine_ref_ortho_camera_size = sz
				factor *= clampf(_spine_ref_ortho_camera_size / maxf(0.01, sz), 0.4, 2.5)
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
