extends CanvasLayer
## UI controller that wires ColorPickerButton nodes to a CharacterCustomizer.
## Attach this script to a CanvasLayer in your customization scene.
##
## Workflow (matches the video):
##   1. Player picks a color in a ColorPickerButton.
##   2. The "color_changed" signal fires.
##   3. This script calls the appropriate method on CharacterCustomizer.
##   4. The shader updates the sprite instantly.

## Path to the CharacterCustomizer node (child of the target Sprite2D).
@export var customizer_path: NodePath

## References to ColorPickerButton nodes in the UI (set in the Inspector).
@export var body_picker: ColorPickerButton
@export var eye_picker: ColorPickerButton
@export var detail1_picker: ColorPickerButton
@export var detail2_picker: ColorPickerButton

var _customizer: CharacterCustomizer

func _ready() -> void:
	# Resolve the customizer reference
	if customizer_path:
		_customizer = get_node_or_null(customizer_path)
	if not _customizer:
		push_warning("CustomizationUI: CharacterCustomizer node not found at path: ", customizer_path)
		return

	# Disable alpha editing on every picker (characters don't need transparency)
	_disable_alpha(body_picker)
	_disable_alpha(eye_picker)
	_disable_alpha(detail1_picker)
	_disable_alpha(detail2_picker)

	# Connect signals
	if body_picker:
		body_picker.color_changed.connect(_on_body_color_changed)
	if eye_picker:
		eye_picker.color_changed.connect(_on_eye_color_changed)
	if detail1_picker:
		detail1_picker.color_changed.connect(_on_detail1_color_changed)
	if detail2_picker:
		detail2_picker.color_changed.connect(_on_detail2_color_changed)

# ── Signal callbacks ──

func _on_body_color_changed(color: Color) -> void:
	if _customizer:
		_customizer.set_body_color(color)

func _on_eye_color_changed(color: Color) -> void:
	if _customizer:
		_customizer.set_eye_color(color)

func _on_detail1_color_changed(color: Color) -> void:
	if _customizer:
		_customizer.set_detail1_color(color)

func _on_detail2_color_changed(color: Color) -> void:
	if _customizer:
		_customizer.set_detail2_color(color)

# ── Helpers ──

func _disable_alpha(picker: ColorPickerButton) -> void:
	if picker:
		# Defer so the internal ColorPicker is ready
		picker.call_deferred("set_edit_alpha", false)
