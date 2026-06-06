extends Node

const SETTINGS_PATH := "user://audio_settings.json"
const MASTER_BUS := "Master"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const DEFAULT_VOLUMES := {
	"Master": 100.0,
	"SFX": 100.0,
	"Music": 100.0,
}

var volumes: Dictionary = DEFAULT_VOLUMES.duplicate()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	load_settings()
	apply_all()


func set_volume_percent(bus_name: String, value: float, save_after_change := true) -> void:
	var clean_bus: String = _normalize_bus_name(bus_name)
	var clean_value: float = clampf(value, 0.0, 100.0)
	volumes[clean_bus] = clean_value
	_apply_bus_volume(clean_bus, clean_value)

	if save_after_change:
		save_settings()


func get_volume_percent(bus_name: String) -> float:
	return float(volumes.get(_normalize_bus_name(bus_name), 100.0))


func apply_all() -> void:
	_ensure_audio_buses()

	for bus_name in DEFAULT_VOLUMES:
		_apply_bus_volume(bus_name, get_volume_percent(bus_name))


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if file == null:
		return

	var data = JSON.parse_string(file.get_as_text())

	if not (data is Dictionary):
		return

	for bus_name in DEFAULT_VOLUMES:
		if data.has(bus_name):
			volumes[bus_name] = clampf(float(data[bus_name]), 0.0, 100.0)


func save_settings() -> void:
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)

	if file == null:
		push_warning("Could not save audio settings: %s" % FileAccess.get_open_error())
		return

	file.store_string(JSON.stringify(volumes))


func _ensure_audio_buses() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(MUSIC_BUS)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus()
	var bus_index: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, MASTER_BUS)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))


func _normalize_bus_name(bus_name: String) -> String:
	if DEFAULT_VOLUMES.has(bus_name):
		return bus_name

	return MASTER_BUS
