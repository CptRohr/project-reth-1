extends Node

const NPC_DATA_PATH := "res://data/npc/npcs.json"

var npcs: Array = []
var npcs_by_id: Dictionary = {}
var appearance_rules: Array = []
var dialogue_routes: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	var data = _load_json(NPC_DATA_PATH)

	if data is Dictionary:
		npcs = data.get("npcs", [])
		appearance_rules = data.get("appearance_rules", [])
		dialogue_routes = data.get("dialogue_routes", [])
	else:
		npcs = []
		appearance_rules = []
		dialogue_routes = []

	_rebuild_npc_index()


func get_npc(npc_id: String) -> Dictionary:
	var key := npc_id.strip_edges()

	if npcs_by_id.has(key):
		return npcs_by_id[key].duplicate(true)

	return {}


func is_npc_visible(npc_id: String, scene_path: String, active_flags) -> bool:
	var rule := _get_matching_appearance_rule(npc_id, scene_path, active_flags)

	if not rule.is_empty():
		return bool(rule.get("visible", true))

	var npc := get_npc(npc_id)
	return bool(npc.get("visible_by_default", false))


func is_npc_interactable(npc_id: String, scene_path: String, active_flags) -> bool:
	var rule := _get_matching_appearance_rule(npc_id, scene_path, active_flags)

	if not rule.is_empty():
		return bool(rule.get("visible", true)) and bool(rule.get("interactable", true))

	return bool(get_npc(npc_id).get("visible_by_default", false))


func get_dialogue_timeline(npc_id: String, scene_path: String, active_flags) -> String:
	var route := _get_matching_dialogue_route(npc_id, scene_path, active_flags)

	if not route.is_empty():
		return str(route.get("timeline", ""))

	return str(get_npc(npc_id).get("default_timeline", ""))


func get_dialogue_route_timeline(npc_id: String, scene_path: String, active_flags) -> String:
	var route := _get_matching_dialogue_route(npc_id, scene_path, active_flags)

	if route.is_empty():
		return ""

	return str(route.get("timeline", ""))


func get_set_flags_after_interaction(npc_id: String, scene_path: String, active_flags) -> Array:
	var route := _get_matching_dialogue_route(npc_id, scene_path, active_flags)

	if route.is_empty():
		return []

	var flags = route.get("set_flags_after_interaction", [])
	if flags is Array:
		return flags

	return []


func _get_matching_appearance_rule(npc_id: String, scene_path: String, active_flags) -> Dictionary:
	for rule in appearance_rules:
		if not (rule is Dictionary):
			continue

		if _matches_rule(rule, npc_id, scene_path, active_flags):
			return rule.duplicate(true)

	return {}


func _get_matching_dialogue_route(npc_id: String, scene_path: String, active_flags) -> Dictionary:
	var matches := []

	for route in dialogue_routes:
		if not (route is Dictionary):
			continue

		if _matches_rule(route, npc_id, scene_path, active_flags, false):
			matches.append(route)

	matches.sort_custom(func(a, b): return int(a.get("priority", 0)) < int(b.get("priority", 0)))

	if matches.is_empty():
		return {}

	return matches[0].duplicate(true)


func _matches_rule(rule: Dictionary, npc_id: String, scene_path: String, active_flags, require_scene := true) -> bool:
	if str(rule.get("npc_id", "")) != npc_id:
		return false

	if require_scene or str(rule.get("scene_path", "")) != "":
		if str(rule.get("scene_path", "")) != scene_path:
			return false

	if not _list_allows(rule.get("days", []), _current_day_name()):
		return false

	if not _list_allows(rule.get("dates", []), _current_date_string()):
		return false

	if not _list_allows(rule.get("time_blocks", []), GameState.time_block):
		return false

	if not _required_flags_match(rule.get("required_flags", []), active_flags):
		return false

	if _blocked_flags_match(rule.get("blocked_flags", []), active_flags):
		return false

	return true


func _rebuild_npc_index() -> void:
	npcs_by_id.clear()

	for npc in npcs:
		if not (npc is Dictionary):
			continue

		var npc_id := str(npc.get("id", "")).strip_edges()
		if npc_id != "":
			npcs_by_id[npc_id] = npc


func _load_json(path: String):
	if not FileAccess.file_exists(path):
		push_warning("NPC data file does not exist: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not read NPC data file: %s" % path)
		return null

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("NPC data file is not valid JSON: %s" % path)

	return parsed


func _list_allows(values, current_value: String) -> bool:
	if not (values is Array):
		return true

	if values.is_empty():
		return true

	for value in values:
		if str(value).to_lower() == current_value.to_lower():
			return true

	return false


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


func _blocked_flags_match(blocked_flags, active_flags) -> bool:
	for flag_name in blocked_flags:
		var key := str(flag_name)

		if active_flags is Dictionary and bool(active_flags.get(key, false)):
			return true

		if active_flags is Array and active_flags.has(key):
			return true

	return false


func _current_day_name() -> String:
	var calendar_manager = get_node_or_null("/root/CalendarManager")

	if calendar_manager == null:
		return ""

	return calendar_manager.get_current_day_name()


func _current_date_string() -> String:
	var calendar_manager = get_node_or_null("/root/CalendarManager")

	if calendar_manager == null:
		return ""

	return calendar_manager.get_current_date_string()
