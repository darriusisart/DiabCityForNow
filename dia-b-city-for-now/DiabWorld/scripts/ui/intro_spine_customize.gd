extends CanvasLayer
## Post-quiz character setup: Spine skin + optional per-slot colors.
## Set [member tint_slot_names] to your skeleton slot names (Spine editor) for color rows.

signal customization_finished

const SPINE_SCENE := preload("res://DiabWorld/splineplayer/newestspine/spineplayer.tscn")
const _POPPINS: Font = preload("res://Font/Poppins/Poppins-Regular.ttf")

@export var idle_animation: String = "DarkMale_IdleAnimation"
## Slot names from your Spine skeleton (Debug → slots in editor). Empty = outfit (skin) only.
@export var tint_slot_names: PackedStringArray = PackedStringArray()
## Per-part attachment presets. Format per entry:
## "Label|SlotName|attachment_a,attachment_b,attachment_c"
@export var part_attachment_presets: PackedStringArray = PackedStringArray()

var _spine: Node = null
var _skin_option: OptionButton = null
var _slot_to_picker: Dictionary = {}
var _part_to_option: Dictionary = {}
var _slot_vbox: VBoxContainer = null
var _slot_hint: Label = null
var _global_tint_picker: ColorPickerButton = null
var _parts_vbox: VBoxContainer = null

func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	await get_tree().process_frame
	_setup_spine_preview()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 28)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)
	var vpc := SubViewportContainer.new()
	vpc.custom_minimum_size = Vector2(540, 720)
	vpc.stretch = true
	var vp := SubViewport.new()
	vp.size = Vector2i(540, 720)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var root2d := Node2D.new()
	_spine = SPINE_SCENE.instantiate()
	root2d.add_child(_spine)
	_spine.position = Vector2(270, 620)
	_spine.scale = Vector2(0.085, 0.085)
	vp.add_child(root2d)
	vpc.add_child(vp)
	hbox.add_child(vpc)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(420, 0)
	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 16)
	pm.add_theme_constant_override("margin_top", 16)
	pm.add_theme_constant_override("margin_right", 16)
	pm.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(pm)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	pm.add_child(vbox)
	var title := Label.new()
	title.text = "Character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_lbl(title, 28)
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "Pick an outfit (Spine=-=-=skin). Add slot names on this node to tint clothes."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_lbl(sub, 15)
	sub.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82, 1.0))
	vbox.add_child(sub)
	var outfit_row := HBoxContainer.new()
	var ol := Label.new()
	ol.text = "Outfit"
	ol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_lbl(ol, 18)
	_skin_option = OptionButton.new()
	_skin_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outfit_row.add_child(ol)
	outfit_row.add_child(_skin_option)
	vbox.add_child(outfit_row)
	var tint_row := HBoxContainer.new()
	var tl := Label.new()
	tl.text = "Global Tint"
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_lbl(tl, 18)
	_global_tint_picker = ColorPickerButton.new()
	_global_tint_picker.custom_minimum_size = Vector2(88, 32)
	_global_tint_picker.edit_alpha = false
	_global_tint_picker.color = Data.player_spine_global_tint if Data.player_spine_global_tint is Color else Color.WHITE
	_global_tint_picker.color_changed.connect(_on_global_tint_changed)
	tint_row.add_child(tl)
	tint_row.add_child(_global_tint_picker)
	vbox.add_child(tint_row)
	var parts_title := Label.new()
	parts_title.text = "Body Part Presets"
	_style_lbl(parts_title, 18)
	vbox.add_child(parts_title)
	_parts_vbox = VBoxContainer.new()
	_parts_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(_parts_vbox)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 280)
	_slot_vbox = VBoxContainer.new()
	_slot_vbox.add_theme_constant_override("separation", 8)
	_slot_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_slot_vbox)
	vbox.add_child(scroll)
	_slot_hint = Label.new()
	_slot_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_lbl(_slot_hint, 14)
	_slot_hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82, 1.0))
	_slot_hint.text = "Loading slot names from Spine..."
	vbox.add_child(_slot_hint)
	var done := Button.new()
	done.text = "Start"
	done.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(done)
	done.pressed.connect(_on_done_pressed)
	hbox.add_child(panel)

func _style_lbl(l: Label, fs: int) -> void:
	l.add_theme_font_override("font", _POPPINS)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 1.0))

func _setup_spine_preview() -> void:
	if _spine == null:
		return
	var skins := SpineAppearance.list_skin_names(_spine)
	_skin_option.clear()
	for s in skins:
		_skin_option.add_item(s)
	var current := Data.player_spine_skin
	var idx := skins.find(current)
	if idx < 0:
		idx = 0
	_skin_option.select(idx)
	SpineAppearance.apply_skin_by_name(_spine, _skin_option.get_item_text(_skin_option.selected))
	if _global_tint_picker != null:
		_apply_picker_icon_color(_global_tint_picker, _global_tint_picker.color)
		SpineAppearance.set_global_tint(_spine, _global_tint_picker.color)
	_rebuild_part_rows()
	_apply_selected_part_attachments()
	var slot_names := SpineAppearance.list_slot_names(_spine)
	var effective_slots := _resolve_tint_slots(slot_names)
	_rebuild_slot_rows(effective_slots)
	for sn in _slot_to_picker.keys():
		var c: Color = _slot_to_picker[sn].color
		SpineAppearance.set_slot_color(_spine, sn, c)
	SpineAppearance.play_idle(_spine, idle_animation)
	_skin_option.item_selected.connect(_on_skin_selected)
	if _slot_hint != null:
		_slot_hint.text = "Spine slots loaded: %d. Changing only works for exact slot names." % effective_slots.size()

func _on_skin_selected(index: int) -> void:
	if _spine == null:
		return
	var name := _skin_option.get_item_text(index)
	SpineAppearance.apply_skin_by_name(_spine, name)
	if _global_tint_picker != null:
		SpineAppearance.set_global_tint(_spine, _global_tint_picker.color)
	_apply_selected_part_attachments()
	for sn in _slot_to_picker.keys():
		SpineAppearance.set_slot_color(_spine, sn, _slot_to_picker[sn].color)
	SpineAppearance.play_idle(_spine, idle_animation)

func _on_slot_color_changed(new_color: Color, slot_name: String) -> void:
	if _spine == null:
		return
	var picker: ColorPickerButton = _slot_to_picker.get(slot_name, null) as ColorPickerButton
	if picker != null:
		_apply_picker_icon_color(picker, new_color)
	SpineAppearance.set_slot_color(_spine, slot_name, new_color)

func _on_global_tint_changed(new_color: Color) -> void:
	if _spine == null:
		return
	if _global_tint_picker != null:
		_apply_picker_icon_color(_global_tint_picker, new_color)
	SpineAppearance.set_global_tint(_spine, new_color)

func _on_part_selected(index: int, part_key: String) -> void:
	if _spine == null:
		return
	var opt: OptionButton = _part_to_option.get(part_key, null) as OptionButton
	if opt == null or index < 0:
		return
	var attachment := opt.get_item_text(index)
	SpineAppearance.set_slot_attachment(_spine, part_key, attachment)

func _resolve_tint_slots(all_slot_names: PackedStringArray) -> PackedStringArray:
	if all_slot_names.is_empty():
		return tint_slot_names
	if tint_slot_names.is_empty():
		return all_slot_names
	var out := PackedStringArray()
	for raw_name in tint_slot_names:
		var n := str(raw_name).strip_edges()
		if n != "" and all_slot_names.has(n):
			out.append(n)
	if out.is_empty():
		return all_slot_names
	return out

func _rebuild_slot_rows(slot_names: PackedStringArray) -> void:
	if _slot_vbox == null:
		return
	for child in _slot_vbox.get_children():
		_slot_vbox.remove_child(child)
		child.queue_free()
	_slot_to_picker.clear()
	for slot_name in slot_names:
		var sn := str(slot_name).strip_edges()
		if sn == "":
			continue
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.text = sn
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_lbl(lab, 16)
		var pick := ColorPickerButton.new()
		pick.custom_minimum_size = Vector2(88, 32)
		pick.edit_alpha = false
		pick.color = Color(1, 1, 1, 1)
		var saved: Variant = Data.player_spine_slot_tints.get(sn, Color.WHITE)
		if saved is Color:
			pick.color = saved
		pick.color_changed.connect(_on_slot_color_changed.bind(sn))
		row.add_child(lab)
		row.add_child(pick)
		_slot_vbox.add_child(row)
		_slot_to_picker[sn] = pick
		_apply_picker_icon_color(pick, pick.color)
		pick.call_deferred("set_edit_alpha", false)

func _rebuild_part_rows() -> void:
	if _parts_vbox == null:
		return
	for child in _parts_vbox.get_children():
		_parts_vbox.remove_child(child)
		child.queue_free()
	_part_to_option.clear()
	for entry in part_attachment_presets:
		var raw := String(entry).strip_edges()
		if raw == "":
			continue
		var segments := raw.split("|")
		if segments.size() < 3:
			continue
		var label_text := segments[0].strip_edges()
		var slot_name := segments[1].strip_edges()
		var attachments := segments[2].split(",", false)
		if slot_name == "" or attachments.is_empty():
			continue
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = label_text if label_text != "" else slot_name
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_lbl(lbl, 16)
		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for a in attachments:
			var an := String(a).strip_edges()
			if an != "":
				opt.add_item(an)
		if opt.item_count == 0:
			continue
		var saved := String(Data.player_spine_part_attachments.get(slot_name, "")).strip_edges()
		var idx := -1
		for i in opt.item_count:
			if opt.get_item_text(i) == saved:
				idx = i
				break
		if idx < 0:
			idx = 0
		opt.select(idx)
		opt.item_selected.connect(_on_part_selected.bind(slot_name))
		row.add_child(lbl)
		row.add_child(opt)
		_parts_vbox.add_child(row)
		_part_to_option[slot_name] = opt

func _apply_selected_part_attachments() -> void:
	if _spine == null:
		return
	for slot_name in _part_to_option.keys():
		var opt: OptionButton = _part_to_option[slot_name] as OptionButton
		if opt == null or opt.selected < 0:
			continue
		var attachment := opt.get_item_text(opt.selected)
		SpineAppearance.set_slot_attachment(_spine, String(slot_name), attachment)

func _apply_picker_icon_color(pick: ColorPickerButton, c: Color) -> void:
	if pick == null:
		return
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(c)
	var tex := ImageTexture.create_from_image(img)
	pick.icon = tex

func _on_done_pressed() -> void:
	var skin := _skin_option.get_item_text(_skin_option.selected)
	Data.player_spine_skin = skin
	var tints: Dictionary = {}
	for sn in _slot_to_picker.keys():
		tints[sn] = _slot_to_picker[sn].color
	Data.player_spine_slot_tints = tints
	var parts: Dictionary = {}
	for slot_name in _part_to_option.keys():
		var opt: OptionButton = _part_to_option[slot_name] as OptionButton
		if opt == null or opt.selected < 0:
			continue
		parts[String(slot_name)] = opt.get_item_text(opt.selected)
	Data.player_spine_part_attachments = parts
	if _global_tint_picker != null:
		Data.player_spine_global_tint = _global_tint_picker.color
	customization_finished.emit()
	queue_free()
