extends Node3D
signal dialog_closed(choice: String)

@export var display_name := "Classmate"
@export var chat_pillar := "social"
@export var chat_xp := 6
@export var race_exercise_xp := 8
@export var race_social_xp := 3
@export var convo_topics: PackedStringArray = [
	"how to start a windowsill herb garden with mint and basil",
	"an easy lunch swap: water + fruit instead of soda + candy",
	"one PE warmup move that helps prevent ankle and knee strain",
	"a quick label-reading trick: if sugar is in the top ingredients, pick another option",
	"an after-school activity idea that boosts mood and sleep quality"
]

func interact(player: Node) -> void:
	if player.has_method("set_ui_locked"):
		player.set_ui_locked(true)
	var layer := CanvasLayer.new()
	layer.layer = 110
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220.0
	panel.offset_top = -130.0
	panel.offset_right = 220.0
	panel.offset_bottom = 130.0
	layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "Chat, race, or close."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	var choice_made := ""
	var btn_chat := Button.new()
	btn_chat.text = "Chat"
	var btn_race := Button.new()
	btn_race.text = "Race"
	var btn_close := Button.new()
	btn_close.text = "Close"
	row.add_child(btn_chat)
	row.add_child(btn_race)
	row.add_child(btn_close)
	var end_dialog := func(choice: String) -> void:
		choice_made = choice
		emit_signal("dialog_closed", choice)
		if is_instance_valid(layer):
			layer.queue_free()
	btn_chat.pressed.connect(end_dialog.bind("chat"))
	btn_race.pressed.connect(end_dialog.bind("race"))
	btn_close.pressed.connect(end_dialog.bind(""))
	await self.dialog_closed
	if player.has_method("set_ui_locked"):
		player.set_ui_locked(false)
	if choice_made == "chat":
		await _run_persona_chat(player)
	elif choice_made == "race":
		var won: bool = await _run_recess_race_minigame(player)
		var pl2: Node = Data.pillars()
		if pl2 != null and pl2.has_method("add_xp"):
			pl2.add_xp("exercise", race_exercise_xp if won else 3, "recess_race")
			pl2.add_xp("social", race_social_xp, "recess_friendly_competition")

func _pick_topic() -> String:
	if convo_topics.is_empty():
		return "school and weekend plans"
	return convo_topics[randi() % convo_topics.size()]

func _run_persona_chat(_player: Node) -> void:
	var topic := _pick_topic()
	var line_a := "You and %s talk about %s." % [display_name, topic]
	var line_b := "%s asks what you would try first this week." % display_name
	var line_c := "You trade one small idea and agree to check in later."

	var layer := CanvasLayer.new()
	layer.layer = 111
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280.0
	panel.offset_top = -200.0
	panel.offset_right = 280.0
	panel.offset_bottom = 200.0
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(480, 0)
	vbox.add_child(body)

	var choice_row := HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 8)
	vbox.add_child(choice_row)

	var state := {"step": 0, "tone": "warm"}
	var btn1 := Button.new()
	var btn2 := Button.new()
	var btn3 := Button.new()
	choice_row.add_child(btn1)
	choice_row.add_child(btn2)
	choice_row.add_child(btn3)

	var cleanup := func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()

	var apply_step := func() -> void:
		match int(state.step):
			0:
				body.text = "[b]%s[/b]\n%s" % [display_name, line_a]
				btn1.text = "Share a real detail"
				btn2.text = "Crack a small joke"
				btn3.text = "Keep it short"
			1:
				var extra := ""
				match state.tone:
					"warm":
						extra = "They light up — you both sound more relaxed."
					"joke":
						extra = "They laugh; the chat feels easy."
					_:
						extra = "They nod; no pressure either way."
				body.text = "[b]%s[/b]\n%s\n\n%s" % [display_name, line_b, extra]
				btn1.text = "Offer a plan"
				btn2.text = "Ask a follow-up"
				btn3.text = "Wish them well"
			_:
				body.text = "[b]%s[/b]\n%s" % [display_name, line_c]
				btn1.text = "Nice — close"
				btn2.visible = false
				btn3.visible = false

	var on_pick := func(kind: String) -> void:
		if int(state.step) == 0:
			state.tone = kind
			state.step = 1
			apply_step.call()
			return
		if int(state.step) == 1:
			state.step = 2
			apply_step.call()
			return
		var pl: Node = Data.pillars()
		if pl != null and pl.has_method("add_xp"):
			pl.add_xp(chat_pillar, chat_xp, "recess_classmate_chat")
			pl.add_xp("social", 1, "recess_chat_topic")
		print(line_a)
		cleanup.call()

	btn1.pressed.connect(func() -> void:
		if int(state.step) < 2:
			on_pick.call("warm" if int(state.step) == 0 else "plan")
		else:
			on_pick.call("")
	)
	btn2.pressed.connect(func() -> void:
		if int(state.step) == 0:
			on_pick.call("joke")
		elif int(state.step) == 1:
			on_pick.call("followup")
	)
	btn3.pressed.connect(func() -> void:
		if int(state.step) == 0:
			on_pick.call("short")
		elif int(state.step) == 1:
			on_pick.call("well")
	)

	apply_step.call()
	await layer.tree_exited

func _run_recess_race_minigame(player: Node) -> bool:
	var cam: Camera3D = null
	var rig: Node3D = null
	var old_ortho := 8.5
	var old_pos := Vector3.ZERO
	if player != null:
		rig = player.get_node_or_null("../camera_rig")
		if rig == null:
			rig = _find_camera_rig(player)
		if rig != null:
			cam = rig.get_node_or_null("Camera3D") as Camera3D
			if cam != null and cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
				old_ortho = cam.size
				old_pos = rig.global_position
				var tw := create_tween()
				tw.tween_property(cam, "size", old_ortho * 0.78, 0.35)

	var layer := CanvasLayer.new()
	layer.layer = 125
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.06, 0.1, 0.92)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var center := Control.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(560, 420)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var countdown := Label.new()
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.add_theme_font_size_override("font_size", 56)
	countdown.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	vbox.add_child(countdown)

	var instr := Label.new()
	instr.text = "Spam SPACE to sprint — beat the runner on your right!"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instr.add_theme_font_size_override("font_size", 18)
	vbox.add_child(instr)

	var you_bar_bg := ColorRect.new()
	you_bar_bg.color = Color(0.2, 0.22, 0.28)
	you_bar_bg.custom_minimum_size = Vector2(500, 28)
	vbox.add_child(you_bar_bg)
	var you_fill := ColorRect.new()
	you_fill.color = Color(0.35, 0.95, 0.55)
	you_fill.size = Vector2(0, 28)
	you_bar_bg.add_child(you_fill)
	var you_lbl := Label.new()
	you_lbl.text = "You"
	you_lbl.position = Vector2(6, 4)
	you_lbl.add_theme_font_size_override("font_size", 14)
	you_bar_bg.add_child(you_lbl)

	var rival_bar_bg := ColorRect.new()
	rival_bar_bg.color = Color(0.2, 0.22, 0.28)
	rival_bar_bg.custom_minimum_size = Vector2(500, 28)
	vbox.add_child(rival_bar_bg)
	var rival_fill := ColorRect.new()
	rival_fill.color = Color(0.95, 0.45, 0.38)
	rival_fill.size = Vector2(0, 28)
	rival_bar_bg.add_child(rival_fill)
	var rival_lbl := Label.new()
	rival_lbl.text = "Classmate (right)"
	rival_lbl.position = Vector2(6, 4)
	rival_lbl.add_theme_font_size_override("font_size", 14)
	rival_bar_bg.add_child(rival_lbl)

	var result := Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 22)
	vbox.add_child(result)

	for t in range(3, 0, -1):
		countdown.text = str(t)
		await get_tree().create_timer(1.0).timeout
	countdown.text = "GO!"
	countdown.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	await get_tree().create_timer(0.45).timeout
	countdown.visible = false

	var you_prog := 0.0
	var rival_prog := 0.0
	var race_time := 0.0
	var done := false
	var won := false
	var race_sec := 5.5
	var last_usec := Time.get_ticks_usec()
	const BAR_PX := 500.0

	while not done:
		await get_tree().process_frame
		var now_usec := Time.get_ticks_usec()
		var d := float(now_usec - last_usec) / 1_000_000.0
		last_usec = now_usec
		d = clampf(d, 0.0, 0.05)
		race_time += d
		rival_prog += (0.09 + randf() * 0.055) * d
		if Input.is_action_just_pressed("Jump"):
			you_prog += 0.042 + randf() * 0.018
		you_prog = clampf(you_prog, 0.0, 1.0)
		rival_prog = clampf(rival_prog, 0.0, 1.0)
		you_fill.size.x = BAR_PX * you_prog
		rival_fill.size.x = BAR_PX * rival_prog
		if you_prog >= 1.0 or rival_prog >= 1.0:
			done = true
			won = you_prog >= rival_prog
		elif race_time >= race_sec:
			done = true
			won = you_prog > rival_prog

	result.text = "You win!" if won else "They edge you out!"
	result.modulate = Color(0.6, 1.0, 0.65) if won else Color(1.0, 0.65, 0.55)
	await get_tree().create_timer(1.1).timeout
	layer.queue_free()

	if cam != null and rig != null:
		var tw2 := create_tween()
		tw2.tween_property(cam, "size", old_ortho, 0.4)
	return won

func _find_camera_rig(from: Node) -> Node3D:
	var n: Node = from
	for _i in range(8):
		if n == null:
			break
		var p := n.get_parent()
		if p != null and str(p.name).findn("camera") >= 0:
			return p as Node3D
		n = p
	return null
