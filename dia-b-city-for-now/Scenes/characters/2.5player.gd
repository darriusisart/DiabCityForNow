extends CharacterBody2D

var ToggleInt := 1

var direction: Vector2
var speed := 50
var can_move: bool = true
@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")
var current_tool: Enums.Tool
var current_seed: Enums.Seed

func _physics_process(_delta: float) -> void:
	#physical actions called in here
	if can_move:
		move()
		animate()
		get_basic_input()

func get_basic_input():
	#cycles between all the tool enums so when you press "action" after tool_forw/tool_back its a differenet tool
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward")
		#print(dir) #Q = -1/E = 1
		current_tool = posmod(current_tool + int(dir),  Enums.Tool.size()) as Enums.Tool
		print(current_tool) 
		
	#cycles between all seed enums so when "action" is pressed toggle between seeds
	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod(current_seed + 1, Enums.Seed.size()) as Enums.Seed
		print(current_seed)
		
	#if pressed do something once
	if Input.is_action_just_pressed("action"):
		tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
		$Animation/AnimationTree.set("parameters/ToolOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func move():
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()

func animate():
	#if we are moving, change to the walking blendspace, and set the blend postion as you move 
	#so you go where you're trying to go and stop in the last known direction
	#TODO fix tool animation direction, it always goes to the down version 
	if direction:
		move_state_machine.travel('WalkBlend') 
		var direction_animation = Vector2(round(direction.x), round(direction.y)) #makes it integer so it knows exactly what animation to play when
		$Animation/AnimationTree.set("parameters/MoveStateMachine/IdleBlend/blend_position", direction_animation) 
		$Animation/AnimationTree.set("parameters/MoveStateMachine/WalkBlend/blend_position", direction_animation)
		for animation in Data.TOOL_STATE_ANIMATIONS.values():
			var animation_name: String = "parameters/MoveStateMachine/" + animation + "/blend_position"
			$Animation/AnimationTree.set(animation_name, direction_animation)
	else:
		move_state_machine.travel('IdleBlend')

func tool_use_emit():
	print('tool')


func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true


func _on_eye_color_picker_color_changed(color: Color) -> void:
	var mat = $Sprite2D.get_material()
	if mat is ShaderMaterial:
		mat.set_shader_parameter("newColorEyes", color)


func _on_body_color_picker_color_changed(color: Color) -> void:
	var mat = $Sprite2D.get_material()
	if mat is ShaderMaterial:
		mat.set_shader_parameter("newColorBody", color)


func _on_eye_color_picker_pressed() -> void:
	print("pressed")
