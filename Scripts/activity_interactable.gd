extends Area2D

@export var activity_id := "activity"
@export var activity_name := "Activity"
@export_range(1, 4) var time_blocks_to_advance := 1
@export var save_after_activity := true
@export var once_per_day := false
@export var stat_changes: Dictionary = {}

var player_inside := false


func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if not can_do_activity():
			show_debug_message("%s is already done today." % activity_name)
			return

		if once_per_day:
			EventManager.mark_done_today(activity_id)

		GameState.perform_activity(activity_id, activity_name, time_blocks_to_advance, stat_changes)

		if save_after_activity:
			GameState.save_game()

		show_debug_message("%s done. Time: %s." % [activity_name, GameState.get_time_block_label()])


func can_do_activity() -> bool:
	if once_per_day and not EventManager.can_run_today(activity_id):
		return false

	return true


func show_debug_message(message: String) -> void:
	var debug_hud = get_node_or_null("/root/DebugHud")

	if debug_hud != null:
		debug_hud.show_message(message)


func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_inside = true


func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_inside = false
