extends Area2D

@export var save_after_school := true

var player_inside := false


func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if GameState.time_block != "morning":
			show_debug_message("School is only available in the morning.")
			return

		if not get_calendar_manager().is_school_day(GameState.calendar_day_index):
			show_debug_message("There is no school today.")
			return

		SchoolSummary.show_for_current_day(save_after_school)


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
