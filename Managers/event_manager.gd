extends Node


func can_run_once(event_id: String) -> bool:
	return not GameState.get_flag(_completed_flag(event_id), false)


func mark_completed(event_id: String) -> void:
	GameState.set_flag(_completed_flag(event_id), true)


func can_run_today(event_id: String) -> bool:
	return int(GameState.get_flag(_last_day_flag(event_id), 0)) != GameState.day


func mark_done_today(event_id: String) -> void:
	GameState.set_flag(_last_day_flag(event_id), GameState.day)


func choose_timeline(default_timeline: String, timeline_rules: Array) -> String:
	for rule in timeline_rules:
		if _matches_rule(rule):
			return str(rule.get("timeline", default_timeline))

	return default_timeline


func _matches_rule(rule: Dictionary) -> bool:
	if rule.has("day_min") and GameState.day < int(rule["day_min"]):
		return false

	if rule.has("day_max") and GameState.day > int(rule["day_max"]):
		return false

	if rule.has("time_block") and GameState.time_block != str(rule["time_block"]):
		return false

	for flag_name in rule.get("flags", []):
		if not GameState.get_flag(str(flag_name), false):
			return false

	for flag_name in rule.get("not_flags", []):
		if GameState.get_flag(str(flag_name), false):
			return false

	return true


func _completed_flag(event_id: String) -> String:
	return "event.%s.completed" % event_id


func _last_day_flag(event_id: String) -> String:
	return "event.%s.last_day" % event_id
