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


func perform_activity(activity_id: String, activity_name := "", time_blocks_to_advance := 1, stat_changes: Dictionary = {}) -> void:
	apply_stat_changes(stat_changes)
	activity_completed.emit(activity_id, activity_name)
	advance_time_block(time_blocks_to_advance)


func apply_stat_changes(stat_changes: Dictionary) -> void:
	for stat_name in stat_changes:
		var change := int(stat_changes[stat_name])
		var current_value := int(stats.get(stat_name, 0))
		var new_value := current_value + change

		stats[stat_name] = new_value
		stat_changed.emit(stat_name, new_value, change)

	if not stat_changes.is_empty():
		state_changed.emit()


func get_stat(stat_name: String, default_value := 0) -> int:
	return int(stats.get(stat_name, default_value))


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
	stats = data.get("stats", {})
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
