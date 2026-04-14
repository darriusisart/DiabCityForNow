extends Node
class_name CharacterCustomizer
## Manages runtime color customization for a sprite using a shader.
## Attach this as a child of the Sprite2D (or any CanvasItem) that has the
## character_color_advanced.gdshader applied as its material.
##
## Call set_body_color(), set_eye_color(), etc. from UI signals or code.
## The shader swaps oldColor → newColor while preserving the original shading.

## Emitted whenever any customization color changes.
signal colors_changed

# ── Cached reference to the ShaderMaterial on the parent sprite ──
var _material: ShaderMaterial

func _ready() -> void:
	# Grab the ShaderMaterial from the parent node
	var parent = get_parent()
	if parent and parent is CanvasItem:
		var mat = parent.get_material()
		if mat is ShaderMaterial:
			_material = mat
		else:
			push_warning("CharacterCustomizer: parent has no ShaderMaterial.")
	else:
		push_warning("CharacterCustomizer: parent is not a CanvasItem.")

# ────────────────────────────────────────────
#  Public API – call these from UI or scripts
# ────────────────────────────────────────────

## Change the body / skin color.
func set_body_color(color: Color) -> void:
	_set_param("newColorBody", color)

## Change the eye color.
func set_eye_color(color: Color) -> void:
	_set_param("newColorEyes", color)

## Change detail slot 1 (shirt, hair, etc.).
func set_detail1_color(color: Color) -> void:
	_set_param("newColor1", color)

## Change detail slot 2 (pants, accessories, etc.).
func set_detail2_color(color: Color) -> void:
	_set_param("newColor2", color)

## Set the matching precision (0 = exact match only, 1 = very loose).
func set_precision(value: float) -> void:
	_set_param("precision", value)

## Convenience: apply a full set of colors at once from a Dictionary.
## Keys: "body", "eyes", "detail1", "detail2"  → Color values.
func apply_preset(preset: Dictionary) -> void:
	if preset.has("body"):
		set_body_color(preset["body"])
	if preset.has("eyes"):
		set_eye_color(preset["eyes"])
	if preset.has("detail1"):
		set_detail1_color(preset["detail1"])
	if preset.has("detail2"):
		set_detail2_color(preset["detail2"])

## Returns the current customization colors as a Dictionary (useful for saving).
func get_current_colors() -> Dictionary:
	if not _material:
		return {}
	return {
		"body": _material.get_shader_parameter("newColorBody"),
		"eyes": _material.get_shader_parameter("newColorEyes"),
		"detail1": _material.get_shader_parameter("newColor1"),
		"detail2": _material.get_shader_parameter("newColor2"),
	}

# ────────────────────────────────────────────
#  Internal
# ────────────────────────────────────────────
func _set_param(param_name: String, value: Variant) -> void:
	if _material:
		_material.set_shader_parameter(param_name, value)
		colors_changed.emit()
