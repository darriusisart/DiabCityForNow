extends Node
class_name SettingsManager
## Autoload singleton that saves / loads player settings with ConfigFile.
##
## Usage:
##   SettingsManager.set_setting("Audio", "master_volume", 0.8)
##   SettingsManager.save_settings()
##   var vol = SettingsManager.get_setting("Audio", "master_volume", 1.0)
##
## Register as an autoload in Project → Project Settings → Globals:
##   Name: Settings   Path: res://SettingsSystem/settings_manager.gd

const SETTINGS_PATH := "user://settings.cfg"

## Emitted after settings are loaded from disk.
signal settings_loaded
## Emitted after settings are saved to disk.
signal settings_saved

var _config := ConfigFile.new()

# ──────────────────────────────────────
#  Lifecycle
# ──────────────────────────────────────

func _ready() -> void:
	load_settings()
	_apply_all()

# ──────────────────────────────────────
#  Public API
# ──────────────────────────────────────

## Store a value under [section] → key.  Does NOT auto-save to disk.
func set_setting(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)

## Read a value. Returns `default` if section/key doesn't exist.
func get_setting(section: String, key: String, default: Variant = null) -> Variant:
	return _config.get_value(section, key, default)

## Write the current config to disk.
func save_settings() -> void:
	var err = _config.save(SETTINGS_PATH)
	if err == OK:
		print("[Settings] Saved to ", SETTINGS_PATH)
		settings_saved.emit()
	else:
		push_error("[Settings] Failed to save: ", err)

## Load config from disk (called automatically in _ready).
func load_settings() -> void:
	var err = _config.load(SETTINGS_PATH)
	if err == OK:
		print("[Settings] Loaded from ", SETTINGS_PATH)
		settings_loaded.emit()
	elif err == ERR_FILE_NOT_FOUND:
		print("[Settings] No settings file found – using defaults.")
		_set_defaults()
		save_settings()
	else:
		push_error("[Settings] Failed to load: ", err)

## Convenience: save a setting AND write to disk in one call.
func set_and_save(section: String, key: String, value: Variant) -> void:
	set_setting(section, key, value)
	save_settings()

# ──────────────────────────────────────
#  Defaults
# ──────────────────────────────────────

func _set_defaults() -> void:
	# Audio
	_config.set_value("Audio", "master_volume", 1.0)
	_config.set_value("Audio", "music_volume", 0.8)
	_config.set_value("Audio", "sfx_volume", 0.8)

	# Video
	_config.set_value("Video", "fullscreen", false)
	_config.set_value("Video", "vsync", true)

# ──────────────────────────────────────
#  Apply loaded settings to the engine
# ──────────────────────────────────────

func _apply_all() -> void:
	_apply_audio()
	_apply_video()

func _apply_audio() -> void:
	var master_vol: float = get_setting("Audio", "master_volume", 1.0)
	var music_vol: float  = get_setting("Audio", "music_volume", 0.8)
	var sfx_vol: float    = get_setting("Audio", "sfx_volume", 0.8)

	_set_bus_volume("Master", master_vol)
	_set_bus_volume("Music", music_vol)
	_set_bus_volume("SFX", sfx_vol)

func _apply_video() -> void:
	var fullscreen: bool = get_setting("Video", "fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	var vsync: bool = get_setting("Video", "vsync", true)
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# ──────────────────────────────────────
#  Helpers
# ──────────────────────────────────────

## Set a bus volume by name. `linear` is 0.0 – 1.0.
func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return  # bus doesn't exist – that's fine, skip silently
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
