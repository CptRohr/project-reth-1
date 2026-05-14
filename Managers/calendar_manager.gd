extends Node

const STORY_YEAR := "20XX"
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
