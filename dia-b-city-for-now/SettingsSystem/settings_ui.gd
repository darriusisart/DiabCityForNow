extends Control
## UI script for the Settings Menu.
## Connects sliders and toggles to the SettingsManager autoload.
##
## Workflow (from the video):
##   1. Player moves a slider / flips a toggle.
##   2. This script updates the setting in SettingsManager.
##   3. The config file saves it.
##   4. Next launch → SettingsManager loads the value automatically.
##
## IMPORTANT: Make sure "Settings" is registered as an autoload pointing to
## res://SettingsSystem/settings_manager.gd  (see project.godot [autoload]).

# ── Node references (set via @export or onready) ──
@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var fullscreen_toggle: CheckButton
@export var vsync_toggle: CheckButton

func _ready() -> void:
	_load_current_values()
	_connect_signals()

# ──────────────────────────────────────
#  Load saved values into the UI
# ──────────────────────────────────────
func _load_current_values() -> void:
	var settings = _get_settings()
	if not settings:
		return

	if master_slider:
		master_slider.value = settings.get_setting("Audio", "master_volume", 1.0)
	if music_slider:
		music_slider.value = settings.get_setting("Audio", "music_volume", 0.8)
	if sfx_slider:
		sfx_slider.value = settings.get_setting("Audio", "sfx_volume", 0.8)
	if fullscreen_toggle:
		fullscreen_toggle.button_pressed = settings.get_setting("Video", "fullscreen", false)
	if vsync_toggle:
		vsync_toggle.button_pressed = settings.get_setting("Video", "vsync", true)

# ──────────────────────────────────────
#  Connect UI signals
# ──────────────────────────────────────
func _connect_signals() -> void:
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if fullscreen_toggle:
		fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if vsync_toggle:
		vsync_toggle.toggled.connect(_on_vsync_toggled)

# ──────────────────────────────────────
#  Signal callbacks
# ──────────────────────────────────────

func _on_master_volume_changed(value: float) -> void:
	var settings = _get_settings()
	if settings:
		settings.set_and_save("Audio", "master_volume", value)
		settings._apply_audio()

func _on_music_volume_changed(value: float) -> void:
	var settings = _get_settings()
	if settings:
		settings.set_and_save("Audio", "music_volume", value)
		settings._apply_audio()

func _on_sfx_volume_changed(value: float) -> void:
	var settings = _get_settings()
	if settings:
		settings.set_and_save("Audio", "sfx_volume", value)
		settings._apply_audio()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	var settings = _get_settings()
	if settings:
		settings.set_and_save("Video", "fullscreen", toggled_on)
		settings._apply_video()

func _on_vsync_toggled(toggled_on: bool) -> void:
	var settings = _get_settings()
	if settings:
		settings.set_and_save("Video", "vsync", toggled_on)
		settings._apply_video()

# ──────────────────────────────────────
#  Helper – get the autoload safely
# ──────────────────────────────────────
func _get_settings() -> Node:
	# "Settings" is the autoload name set in project.godot
	if Engine.has_singleton("Settings"):
		return Engine.get_singleton("Settings")
	# Fallback: try the scene tree autoload path
	return get_node_or_null("/root/Settings")
