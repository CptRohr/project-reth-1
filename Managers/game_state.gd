extends Node

signal day_changed(new_day)
signal time_block_changed(new_time_block)
signal flag_changed(flag_name, value)
signal stat_changed(stat_name, value, amount)
signal activity_completed(activity_id, activity_name)
signal state_loaded
signal state_changed

const SAVE_PATH := "user://save_game.json"
const TIME_BLOCKS := ["morning", "after_school", "evening", "night"]
const TIME_BLOCK_LABELS := {
	"morning": "Morning",
	"after_school": "After School",
	"evening": "Evening",
	"night": "Night",
}
const STAT_MIN := 0
const STAT_MAX := 100
const ENERGY_STAT := "Energy"
const DEFAULT_ENERGY := 100
const PLAYER_STATS := [
	"Knowledge",
	"Charm",
	"Courage",
	"Social",
	"Creativity",
	ENERGY_STAT,
]
var calendar_day_index := 0
var day: int:
	get:
		return calendar_day_index + 1
	set(value):
		calendar_day_index = get_calendar_manager().clamp_day_index(value - 1)
var time_block := "morning"
var flags := {}
var stats := {}
var current_spawn := ""
var current_scene := ""


func set_spawn(spawn_id: String) -> void:
	current_spawn = spawn_id
	state_changed.emit()


func set_scene(scene_path: String) -> void:
	current_scene = scene_path
	state_changed.emit()


func set_flag(flag_name: String, value = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)
	state_changed.emit()


func get_flag(flag_name: String, default_value = false):
	return flags.get(flag_name, default_value)


func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name)


func clear_flag(flag_name: String) -> void:
	if flags.erase(flag_name):
		flag_changed.emit(flag_name, null)
		state_changed.emit()


func get_time_block_label() -> String:
	return TIME_BLOCK_LABELS.get(time_block, time_block.capitalize())


func get_display_date() -> String:
	return get_calendar_manager().get_display_date(calendar_day_index)


func get_date_key() -> String:
	return str(get_calendar_manager().get_date_info(calendar_day_index)["date_key"])


func set_time_block(new_time_block: String) -> void:
	if not TIME_BLOCKS.has(new_time_block):
		push_warning("Unknown time block: %s" % new_time_block)
		return

	time_block = new_time_block
	time_block_changed.emit(time_block)
	state_changed.emit()


func advance_time_block(amount := 1) -> void:
	for i in range(amount):
		_advance_one_time_block()


func perform_activity(activity_id: String, activity_name := "", time_blocks_to_advance := 1, stat_changes: Dictionary = {}, energy_cost := 0, minimum_energy := -1) -> bool:
	if not can_perform_activity(energy_cost, minimum_energy):
		return false

	apply_stat_changes(stat_changes)
	spend_energy(energy_cost)
	activity_completed.emit(activity_id, activity_name)
	advance_time_block(time_blocks_to_advance)
	return true


func can_perform_activity(energy_cost := 0, minimum_energy := -1) -> bool:
	var required_energy := energy_cost

	if minimum_energy >= 0:
		required_energy = minimum_energy

	return can_spend_energy(required_energy)


func apply_stat_changes(stat_changes: Dictionary) -> void:
	for stat_name in stat_changes:
		var change := int(stat_changes[stat_name])
		add_stat(str(stat_name), change, false)

	if not stat_changes.is_empty():
		state_changed.emit()


func get_stat(stat_name: String, default_value := 0) -> int:
	return int(stats.get(stat_name, default_value))


func set_stat(stat_name: String, value: int) -> void:
	var old_value := get_stat(stat_name, get_default_stat_value(stat_name))
	var new_value := clamp_stat_value(value)
	stats[stat_name] = new_value
	stat_changed.emit(stat_name, new_value, new_value - old_value)
	state_changed.emit()


func add_stat(stat_name: String, amount: int, emit_state_update := true) -> void:
	var old_value := get_stat(stat_name, get_default_stat_value(stat_name))
	var new_value := clamp_stat_value(old_value + amount)
	stats[stat_name] = new_value
	stat_changed.emit(stat_name, new_value, new_value - old_value)

	if emit_state_update:
		state_changed.emit()


func can_spend_energy(amount: int) -> bool:
	return get_stat(ENERGY_STAT, DEFAULT_ENERGY) >= max(amount, 0)


func spend_energy(amount: int) -> bool:
	var energy_cost: int = max(amount, 0)

	if energy_cost <= 0:
		return true

	if not can_spend_energy(energy_cost):
		return false

	add_stat(ENERGY_STAT, -energy_cost, false)
	state_changed.emit()
	return true


func restore_energy(amount := DEFAULT_ENERGY) -> void:
	set_stat(ENERGY_STAT, amount)


func get_default_stat_value(stat_name: String) -> int:
	if stat_name == ENERGY_STAT:
		return DEFAULT_ENERGY

	return STAT_MIN


func get_player_stats() -> Dictionary:
	ensure_default_stats()
	var player_stats := {}

	for stat_name in PLAYER_STATS:
		player_stats[stat_name] = get_stat(stat_name, get_default_stat_value(stat_name))

	return player_stats


func ensure_default_stats() -> void:
	for stat_name in PLAYER_STATS:
		if not stats.has(stat_name):
			stats[stat_name] = get_default_stat_value(stat_name)
		else:
			stats[stat_name] = clamp_stat_value(int(stats[stat_name]))


func clamp_stat_value(value: int) -> int:
	return int(clamp(value, STAT_MIN, STAT_MAX))


func _advance_one_time_block() -> void:
	var current_index := TIME_BLOCKS.find(time_block)

	if current_index == -1 or current_index == TIME_BLOCKS.size() - 1:
		sleep_to_next_day()
		return

	time_block = TIME_BLOCKS[current_index + 1]
	time_block_changed.emit(time_block)
	state_changed.emit()


func sleep_to_next_day() -> void:
	calendar_day_index = get_calendar_manager().clamp_day_index(calendar_day_index + 1)
	time_block = "morning"
	restore_energy()
	day_changed.emit(day)
	time_block_changed.emit(time_block)
	state_changed.emit()


func finish_morning_school() -> void:
	if time_block == "morning":
		set_time_block("after_school")


func start_new_game() -> void:
	reset_game()


func reset_game() -> void:
	calendar_day_index = 0
	time_block = "morning"
	flags.clear()
	stats.clear()
	ensure_default_stats()
	current_spawn = ""
	current_scene = ""
	state_loaded.emit()
	state_changed.emit()


func to_save_data() -> Dictionary:
	return {
		"calendar_day_index": calendar_day_index,
		"time_block": time_block,
		"flags": flags,
		"stats": stats,
		"current_spawn": current_spawn,
		"current_scene": current_scene,
	}


func load_from_data(data: Dictionary) -> void:
	if data.has("calendar_day_index"):
		calendar_day_index = get_calendar_manager().clamp_day_index(int(data["calendar_day_index"]))
	else:
		calendar_day_index = get_calendar_manager().clamp_day_index(int(data.get("day", 1)) - 1)

	time_block = str(data.get("time_block", "morning"))
	if time_block == "afternoon":
		time_block = "after_school"
	flags = data.get("flags", {})
	var loaded_stats = data.get("stats", {})
	if loaded_stats is Dictionary:
		stats = loaded_stats as Dictionary
	else:
		stats = {}
	ensure_default_stats()
	current_spawn = str(data.get("current_spawn", ""))
	current_scene = str(data.get("current_scene", ""))
	state_loaded.emit()
	state_changed.emit()


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return false

	file.store_string(JSON.stringify(to_save_data()))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("Could not read save file: %s" % FileAccess.get_open_error())
		return false

	var data = JSON.parse_string(file.get_as_text())

	if data is Dictionary:
		load_from_data(data)
		return true

	push_error("Save file is not valid JSON data.")
	return false


func get_calendar_manager():
	return get_node("/root/CalendarManager")
