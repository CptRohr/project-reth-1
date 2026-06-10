extends Node

const STORY_YEAR_NUMBER := 2026
const STORY_YEAR := "2026"
const START_MONTH := 4
const START_DAY := 1
const START_WEEKDAY_INDEX := 0
const WEEKDAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const MONTH_NAMES := {
	1: "January",
	2: "February",
	3: "March",
	4: "April",
	5: "May",
	6: "June",
	7: "July",
	8: "August",
	9: "September",
	10: "October",
	11: "November",
	12: "December",
}
const MONTH_LENGTHS := {
	1: 31,
	2: 28,
	3: 31,
	4: 30,
	5: 31,
	6: 30,
	7: 31,
	8: 31,
	9: 30,
	10: 31,
	11: 30,
	12: 31,
}
const STORY_MONTHS := [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3]
const DAILY_PLANS := {
	"05/12": {
		"planned_activities": ["Study at library"],
		"objectives": ["Study at library"],
		"reminders": [],
		"events": [],
	},
	"05/13": {
		"planned_activities": ["Meet Bella after school"],
		"objectives": ["Meet Bella after school"],
		"reminders": [],
		"events": [],
	},
}

var month_start_indices := {}
var total_days := 0


func _ready() -> void:
	_build_calendar_index()


func _build_calendar_index() -> void:
	total_days = 0
	month_start_indices.clear()

	for month in STORY_MONTHS:
		month_start_indices[month] = total_days
		total_days += MONTH_LENGTHS[month]


func clamp_day_index(day_index: int) -> int:
	_ensure_calendar_index()
	return clamp(day_index, 0, total_days - 1)


func get_date_info(day_index: int) -> Dictionary:
	var clamped_index := clamp_day_index(day_index)
	var month := START_MONTH
	var day_of_month := START_DAY

	for story_month in STORY_MONTHS:
		var month_start := int(month_start_indices[story_month])
		var month_length := int(MONTH_LENGTHS[story_month])

		if clamped_index >= month_start and clamped_index < month_start + month_length:
			month = story_month
			day_of_month = clamped_index - month_start + 1
			break

	var weekday_index := (START_WEEKDAY_INDEX + clamped_index) % WEEKDAYS.size()

	return {
		"day_index": clamped_index,
		"month": month,
		"day": day_of_month,
		"weekday": WEEKDAYS[weekday_index],
		"weekday_index": weekday_index,
		"month_name": MONTH_NAMES[month],
		"date_key": get_date_key(month, day_of_month),
		"display": "%s, %s/%s/%s" % [
			WEEKDAYS[weekday_index],
			_pad_2(month),
			_pad_2(day_of_month),
			STORY_YEAR
		],
	}


func get_display_date(day_index: int) -> String:
	return str(get_date_info(day_index)["display"])


func get_date_key(month: int, day_of_month: int) -> String:
	return "%s/%s" % [_pad_2(month), _pad_2(day_of_month)]


func get_current_date_key() -> String:
	return str(get_date_info(GameState.calendar_day_index)["date_key"])


func get_date_string(day_index: int) -> String:
	var date_info := get_date_info(day_index)
	return "%s-%s-%s" % [
		STORY_YEAR,
		_pad_2(int(date_info["month"])),
		_pad_2(int(date_info["day"]))
	]


func get_current_date_string() -> String:
	return get_date_string(GameState.calendar_day_index)


func get_day_name(day_index: int) -> String:
	return str(get_date_info(day_index)["weekday"]).to_lower()


func get_current_day_name() -> String:
	return get_day_name(GameState.calendar_day_index)


func get_weather_for_day(day_index: int) -> String:
	var calendar_data = get_calendar_data()

	if calendar_data == null:
		return "clear"

	return calendar_data.get_weather_for_date(get_date_string(day_index))


func get_current_weather() -> String:
	return get_weather_for_day(GameState.calendar_day_index)


func get_current_forced_event() -> Dictionary:
	var calendar_data = get_calendar_data()

	if calendar_data == null:
		return {}

	var special_event: Dictionary = calendar_data.get_special_event(
		get_current_date_string(),
		GameState.time_block,
		GameState.flags
	)

	if not special_event.is_empty():
		return special_event

	return calendar_data.get_forced_weekly_event(get_current_day_name(), GameState.time_block)


func get_current_special_event() -> Dictionary:
	var calendar_data = get_calendar_data()

	if calendar_data == null:
		return {}

	return calendar_data.get_special_event(
		get_current_date_string(),
		GameState.time_block,
		GameState.flags
	)


func get_current_forced_activity() -> Dictionary:
	var forced_event: Dictionary = get_current_forced_event()

	if forced_event.is_empty():
		return {}

	var activity_id := str(forced_event.get("activity_id", ""))
	if activity_id == "":
		return {}

	var calendar_data = get_calendar_data()
	if calendar_data == null:
		return {}

	return calendar_data.get_activity(activity_id)


func get_current_objective_event() -> Dictionary:
	var calendar_data = get_calendar_data()

	if calendar_data == null:
		return {}

	return calendar_data.get_active_objective_event(
		get_current_date_string(),
		GameState.time_block,
		GameState.flags
	)


func has_active_required_objective() -> bool:
	var objective_event: Dictionary = get_current_objective_event()
	return not objective_event.is_empty() and bool(objective_event.get("objective_required", false))


func get_special_events_for_day(day_index: int) -> Array:
	var calendar_data = get_calendar_data()

	if calendar_data == null:
		return []

	return calendar_data.get_special_events_for_date(get_date_string(day_index), GameState.flags)


func has_special_events(day_index: int) -> bool:
	return not get_special_events_for_day(day_index).is_empty()


func get_special_event_summary(day_index: int) -> String:
	var events: Array = get_special_events_for_day(day_index)

	if events.is_empty():
		return ""

	var event: Dictionary = events[0]
	return str(event.get("title", event.get("id", "Event")))


func get_current_available_activities() -> Array:
	if are_normal_activities_locked_now():
		return []

	var calendar_data = get_calendar_data()

	if calendar_data == null:
		return []

	return calendar_data.get_available_activities(
		get_current_day_name(),
		GameState.time_block,
		GameState.flags
	)


func get_flags_after_activity(activity_id: String) -> Array:
	var calendar_data = get_calendar_data()
	var flags := []

	if calendar_data == null:
		return flags

	var activity: Dictionary = calendar_data.get_activity(activity_id)
	if not activity.is_empty():
		flags.append_array(_string_array(activity.get("set_flags_after_complete", [])))

	var forced_event: Dictionary = get_current_forced_event()
	if str(forced_event.get("activity_id", "")) == activity_id:
		flags.append_array(_string_array(forced_event.get("set_flags_after_complete", [])))

	var unique_flags := []
	for flag_name in flags:
		if not unique_flags.has(flag_name):
			unique_flags.append(flag_name)

	return unique_flags


func is_current_time_locked_to_forced_activity() -> bool:
	var forced_event: Dictionary = get_current_forced_event()
	return not forced_event.is_empty() and str(forced_event.get("activity_id", "")) != ""


func are_stat_activities_locked_now() -> bool:
	return GameState.time_block == "morning" and is_current_time_locked_to_forced_activity()


func are_normal_activities_locked_now() -> bool:
	return GameState.time_block == "night" or are_stat_activities_locked_now() or has_active_required_objective()


func can_sleep_now() -> bool:
	return GameState.time_block == "night"


func get_sleep_lock_message() -> String:
	return "You can only rest at night."


func can_attend_school_now() -> bool:
	if GameState.time_block != "morning":
		return false

	if not is_school_day(GameState.calendar_day_index):
		return false

	var special_event: Dictionary = get_current_special_event()
	if special_event.is_empty():
		return true

	return _is_school_activity_id(str(special_event.get("activity_id", "")))


func get_school_lock_message() -> String:
	if GameState.time_block != "morning":
		return "School is only available in the morning."

	if not is_school_day(GameState.calendar_day_index):
		return "There is no school today."

	var objective_event: Dictionary = get_current_objective_event()
	if not objective_event.is_empty():
		var blocked_message := str(objective_event.get("objective_blocked_message", "")).strip_edges()
		if blocked_message != "":
			return blocked_message

	var special_event: Dictionary = get_current_special_event()
	if not special_event.is_empty() and not _is_school_activity_id(str(special_event.get("activity_id", ""))):
		var title := str(special_event.get("title", "")).strip_edges()
		if title != "":
			return "You need to handle %s first." % title

		return "Finish the current event first."

	return "School is not available right now."


func can_perform_activity_now(activity_id: String, stat_changes: Dictionary = {}) -> bool:
	if GameState.time_block == "night":
		return false

	var objective_event: Dictionary = get_current_objective_event()
	if not objective_event.is_empty() and bool(objective_event.get("objective_required", false)):
		var objective_activity_id := str(objective_event.get("activity_id", ""))
		if objective_activity_id != "" and activity_id == objective_activity_id:
			return true

		return false

	if not are_stat_activities_locked_now():
		return true

	if stat_changes.is_empty():
		return true

	var forced_event: Dictionary = get_current_forced_event()
	var forced_activity_id := str(forced_event.get("activity_id", ""))

	return forced_activity_id != "" and activity_id == forced_activity_id


func get_activity_lock_message(activity_name := "Activity") -> String:
	if GameState.time_block == "night":
		return "%s is locked at night. Rest to continue the next day." % activity_name

	var objective_event: Dictionary = get_current_objective_event()
	if not objective_event.is_empty() and bool(objective_event.get("objective_required", false)):
		var blocked_message := str(objective_event.get("objective_blocked_message", "")).strip_edges()
		if blocked_message != "":
			return blocked_message

		return "Finish the current objective first."

	var forced_activity: Dictionary = get_current_forced_activity()
	var forced_name := str(forced_activity.get("name", "the required event"))

	if forced_name == "":
		forced_name = "school"

	return "%s is locked during morning. Go to %s first." % [activity_name, forced_name]


func get_current_objective_text() -> String:
	var objective_event: Dictionary = get_current_objective_event()
	if not objective_event.is_empty():
		return str(objective_event.get("objective_text", ""))

	var forced_event: Dictionary = get_current_forced_event()

	if not forced_event.is_empty():
		var completed_objective_event := (
			str(forced_event.get("objective_text", "")).strip_edges() != ""
			and _is_objective_event_complete(forced_event)
		)

		if not completed_objective_event:
			var activity: Dictionary = get_current_forced_activity()
			var activity_name := str(activity.get("name", forced_event.get("activity_id", "")))
			var special_title := str(forced_event.get("title", ""))

			if special_title != "":
				return "%s: %s" % [special_title, activity_name]

			if activity_name != "":
				return "Go to %s" % activity_name

	var daily_summary := get_daily_plan_summary(GameState.calendar_day_index)
	if daily_summary != "":
		return daily_summary

	var available := get_current_available_activities()
	if not available.is_empty():
		var names := []

		for activity in available:
			if activity is Dictionary:
				names.append(str(activity.get("name", activity.get("id", "Activity"))))

		if not names.is_empty():
			return "Choose activity: %s" % ", ".join(names.slice(0, 3))

	if GameState.time_block == "night":
		return "Rest for tomorrow"

	return "Explore or find an activity"


func _is_objective_event_complete(event_data: Dictionary) -> bool:
	var complete_flag := str(event_data.get("objective_complete_flag", "")).strip_edges()

	if complete_flag == "":
		return false

	return bool(GameState.get_flag(complete_flag, false))


func _string_array(values) -> Array:
	var results := []

	if not (values is Array):
		return results

	for value in values:
		var text := str(value).strip_edges()
		if text != "":
			results.append(text)

	return results


func _is_school_activity_id(activity_id: String) -> bool:
	return activity_id == "school"


func advance_time_block(amount := 1) -> void:
	GameState.advance_time_block(amount)


func parse_date_key(date_key: String) -> int:
	_ensure_calendar_index()
	var parts := date_key.split("/")

	if parts.size() != 2:
		return -1

	var month := int(parts[0])
	var day_of_month := int(parts[1])

	if not month_start_indices.has(month):
		return -1

	if day_of_month < 1 or day_of_month > int(MONTH_LENGTHS[month]):
		return -1

	return int(month_start_indices[month]) + day_of_month - 1


func is_school_day(day_index: int) -> bool:
	var date_info := get_date_info(day_index)
	var weekday_index := int(date_info["weekday_index"])
	return weekday_index < 5


func get_routine_label(day_index: int) -> String:
	if is_school_day(day_index):
		return "School"

	return "Free Day"


func get_daily_plan(day_index: int) -> Dictionary:
	var date_key := str(get_date_info(day_index)["date_key"])

	if not DAILY_PLANS.has(date_key):
		return {
			"planned_activities": [],
			"objectives": [],
			"reminders": [],
			"events": [],
		}

	var plan: Dictionary = DAILY_PLANS[date_key].duplicate(true)
	plan["planned_activities"] = plan.get("planned_activities", [])
	plan["objectives"] = plan.get("objectives", [])
	plan["reminders"] = plan.get("reminders", [])
	plan["events"] = plan.get("events", [])
	return plan


func get_current_daily_plan() -> Dictionary:
	return get_daily_plan(GameState.calendar_day_index)


func has_daily_plan(day_index: int) -> bool:
	var plan: Dictionary = get_daily_plan(day_index)
	return (
		not plan["planned_activities"].is_empty()
		or not plan["objectives"].is_empty()
		or not plan["reminders"].is_empty()
		or not plan["events"].is_empty()
		or has_special_events(day_index)
	)


func get_daily_plan_summary(day_index: int) -> String:
	var plan: Dictionary = get_daily_plan(day_index)

	for key in ["objectives", "planned_activities", "reminders", "events"]:
		var entries = plan[key]
		if not entries.is_empty():
			return str(entries[0])

	return ""


func get_month_grid(month: int, selected_day_index: int) -> Array:
	_ensure_calendar_index()
	var cells := []

	if not month_start_indices.has(month):
		return cells

	var month_start := int(month_start_indices[month])
	var month_length := int(MONTH_LENGTHS[month])
	var first_weekday := int(get_date_info(month_start)["weekday_index"])

	for i in range(first_weekday):
		cells.append({})

	for day_of_month in range(1, month_length + 1):
		var day_index := month_start + day_of_month - 1
		cells.append({
			"day_index": day_index,
			"day": day_of_month,
			"is_today": day_index == selected_day_index,
			"routine": get_routine_label(day_index),
			"has_plan": has_daily_plan(day_index),
			"plan_summary": get_daily_plan_summary(day_index),
			"has_special_events": has_special_events(day_index),
			"special_event_summary": get_special_event_summary(day_index),
			"weekday": get_date_info(day_index)["weekday"],
		})

	while cells.size() % 7 != 0:
		cells.append({})

	return cells


func get_story_months() -> Array:
	return STORY_MONTHS.duplicate()


func _pad_2(value: int) -> String:
	if value < 10:
		return "0%s" % value

	return str(value)


func _ensure_calendar_index() -> void:
	if total_days <= 0:
		_build_calendar_index()


func get_calendar_data():
	return get_node_or_null("/root/CalendarData")
