extends Node

const ACTIVITIES_PATH := "res://data/calendar/activities.json"
const WEEKLY_SCHEDULE_PATH := "res://data/calendar/weekly_schedule.json"
const SPECIAL_EVENTS_PATH := "res://data/calendar/special_events.json"
const WEATHER_PATH := "res://data/calendar/weather.json"

var activities: Array = []
var activities_by_id: Dictionary = {}
var weekly_schedule: Dictionary = {}
var special_events: Array = []
var weather_by_date: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	activities = _load_array(ACTIVITIES_PATH)
	weekly_schedule = _load_dictionary(WEEKLY_SCHEDULE_PATH)
	special_events = _load_array(SPECIAL_EVENTS_PATH)
	weather_by_date = _load_dictionary(WEATHER_PATH)
	_rebuild_activity_index()

	if is_inside_tree() and has_node("/root/GameState"):
		get_node("/root/GameState").refresh_weather()


func get_activity(activity_id: String) -> Dictionary:
	var key := activity_id.strip_edges()

	if activities_by_id.has(key):
		return activities_by_id[key].duplicate(true)

	return {}


func get_available_activities(day_name: String, time_block: String, active_flags) -> Array:
	var matches := []
	var normalized_day := day_name.to_lower()

	for activity in activities:
		if not (activity is Dictionary):
			continue

		var activity_data: Dictionary = activity

		if not _array_has_string(activity_data.get("available_days", []), normalized_day):
			continue

		if not _array_has_string(activity_data.get("available_time_blocks", []), time_block):
			continue

		if not _required_flags_match(activity_data.get("required_flags", []), active_flags):
			continue

		matches.append(activity_data.duplicate(true))

	return matches


func get_forced_weekly_event(day_name: String, time_block: String) -> Dictionary:
	var normalized_day := day_name.to_lower()

	if not weekly_schedule.has(normalized_day):
		return {}

	var day_schedule = weekly_schedule[normalized_day]
	if not (day_schedule is Dictionary):
		return {}

	if not day_schedule.has(time_block):
		return {}

	var event_data = day_schedule[time_block]
	if not (event_data is Dictionary):
		return {}

	return event_data.duplicate(true)


func get_special_event(date_string: String, time_block: String, active_flags) -> Dictionary:
	for event in special_events:
		if not (event is Dictionary):
			continue

		var event_data: Dictionary = event

		if str(event_data.get("date", "")) != date_string:
			continue

		if str(event_data.get("time_block", "")) != time_block:
			continue

		if not _required_flags_match(event_data.get("required_flags", []), active_flags):
			continue

		return event_data.duplicate(true)

	return {}


func get_active_objective_event(date_string: String, time_block: String, active_flags) -> Dictionary:
	var event_data := get_special_event(date_string, time_block, active_flags)

	if event_data.is_empty():
		return {}

	if str(event_data.get("objective_text", "")).strip_edges() == "":
		return {}

	var complete_flag := str(event_data.get("objective_complete_flag", "")).strip_edges()
	if complete_flag != "" and _flag_is_active(complete_flag, active_flags):
		return {}

	return event_data


func get_special_events_for_date(date_string: String, active_flags) -> Array:
	var matches := []

	for event in special_events:
		if not (event is Dictionary):
			continue

		var event_data: Dictionary = event

		if str(event_data.get("date", "")) != date_string:
			continue

		if not _required_flags_match(event_data.get("required_flags", []), active_flags):
			continue

		matches.append(event_data.duplicate(true))

	return matches


func get_weather_for_date(date_string: String) -> String:
	var weather_id := str(weather_by_date.get(date_string, "clear")).strip_edges().to_lower()

	if has_node("/root/GameState") and get_node("/root/GameState").is_valid_weather(weather_id):
		return weather_id

	return "clear"


func _rebuild_activity_index() -> void:
	activities_by_id.clear()

	for activity in activities:
		if not (activity is Dictionary):
			continue

		var activity_data: Dictionary = activity
		var activity_id := str(activity_data.get("id", "")).strip_edges()

		if activity_id != "":
			activities_by_id[activity_id] = activity_data


func _load_array(path: String) -> Array:
	var data = _load_json(path)

	if data is Array:
		return data

	return []


func _load_dictionary(path: String) -> Dictionary:
	var data = _load_json(path)

	if data is Dictionary:
		return data

	return {}


func _load_json(path: String):
	if not FileAccess.file_exists(path):
		push_warning("Calendar data file does not exist: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not read calendar data file: %s" % path)
		return null

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Calendar data file is not valid JSON: %s" % path)

	return parsed


func _required_flags_match(required_flags, active_flags) -> bool:
	for flag_name in required_flags:
		var key := str(flag_name)

		if active_flags is Dictionary:
			if not bool(active_flags.get(key, false)):
				return false
		elif active_flags is Array:
			if not active_flags.has(key):
				return false
		else:
			return false

	return true


func _flag_is_active(flag_name: String, active_flags) -> bool:
	if active_flags is Dictionary:
		return bool(active_flags.get(flag_name, false))

	if active_flags is Array:
		return active_flags.has(flag_name)

	return false


func _array_has_string(values, expected_value: String) -> bool:
	if not (values is Array):
		return false

	for value in values:
		if str(value).to_lower() == expected_value:
			return true

	return false
