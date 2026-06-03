extends Area2D

@export var activity_id := "activity"
@export var activity_name := "Activity"
@export_range(1, 4) var time_blocks_to_advance := 1
@export var save_after_activity := true
@export var once_per_day := false
@export var stat_changes: Dictionary = {}
@export_range(0, 100) var energy_cost := 0
@export_range(0, 100) var minimum_energy := 0
@export_multiline var success_message := ""
@export_multiline var not_enough_energy_message := ""

var player_inside := false


func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if once_per_day and not EventManager.can_run_today(activity_id):
			show_debug_message("%s is already done today." % activity_name)
			return

		if not can_do_activity():
			show_debug_message(get_not_enough_energy_message())
			return

		if not GameState.spend_energy(energy_cost):
			show_debug_message(get_not_enough_energy_message())
			return

		if once_per_day:
			EventManager.mark_done_today(activity_id)

		GameState.perform_activity(
			activity_id,
			activity_name,
			time_blocks_to_advance,
			stat_changes
		)

		if save_after_activity:
			GameState.save_game()

		show_debug_message(get_success_message())


func can_do_activity() -> bool:
	if once_per_day and not EventManager.can_run_today(activity_id):
		return false

	if not get_calendar_manager().can_perform_activity_now(activity_id, stat_changes):
		return false

	return GameState.can_perform_activity(energy_cost, get_minimum_energy())


func get_minimum_energy() -> int:
	if minimum_energy > 0:
		return minimum_energy

	return energy_cost


func get_success_message() -> String:
	if success_message != "":
		return success_message

	return "%s done. Energy: %s/%s. Time: %s." % [
		activity_name,
		GameState.get_stat(GameState.ENERGY_STAT, GameState.DEFAULT_ENERGY),
		GameState.DEFAULT_ENERGY,
		GameState.get_time_block_label()
	]


func get_not_enough_energy_message() -> String:
	if not get_calendar_manager().can_perform_activity_now(activity_id, stat_changes):
		return get_calendar_manager().get_activity_lock_message(activity_name)

	if not_enough_energy_message != "":
		return not_enough_energy_message

	return "%s needs at least %s Energy." % [activity_name, get_minimum_energy()]


func show_debug_message(message: String) -> void:
	var debug_hud = get_node_or_null("/root/DebugHud")

	if debug_hud != null:
		debug_hud.show_message(message)


func get_calendar_manager():
	return get_node("/root/CalendarManager")


func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_inside = true


func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_inside = false
