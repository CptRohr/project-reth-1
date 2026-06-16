extends Node2D

@export var npc_id := ""
@export var timeline_name := "test"
@export var timeline_rules: Array[Dictionary] = []

var player_inside = false
var is_interactable := true
var player_ref: Node2D = null

@export_group("Dialogue Camera Override")
@export var override_dialogue_camera := false
@export var dialogue_zoom_factor := 1.25
@export var dialogue_camera_blend := 0.5
@export var dialogue_camera_offset := Vector2(0, 0)


func _ready() -> void:
	_connect_state_signals()
	_refresh_npc_state()


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if not visible or not is_interactable:
			return

		if !Dialogic.current_timeline:
			var chosen_timeline := get_dialogue_timeline()

			if chosen_timeline != "":
				if player_ref and player_ref.has_method("start_dialogue_with"):
					player_ref.start_dialogue_with(self)
				Dialogic.start(chosen_timeline)
				_apply_interaction_flags()


func get_dialogue_timeline() -> String:
	if npc_id != "":
		var npc_data = get_npc_data()

		if npc_data != null:
			var timeline: String = npc_data.get_dialogue_timeline(npc_id, _get_current_scene_path(), GameState.flags)

			if timeline != "":
				return timeline

	return EventManager.choose_timeline(timeline_name, timeline_rules)


func _connect_state_signals() -> void:
	if not GameState.state_changed.is_connected(_refresh_npc_state):
		GameState.state_changed.connect(_refresh_npc_state)

	if not GameState.day_changed.is_connected(_on_day_changed):
		GameState.day_changed.connect(_on_day_changed)

	if not GameState.time_block_changed.is_connected(_on_time_block_changed):
		GameState.time_block_changed.connect(_on_time_block_changed)

	if not GameState.state_loaded.is_connected(_refresh_npc_state):
		GameState.state_loaded.connect(_refresh_npc_state)


func _refresh_npc_state() -> void:
	if npc_id == "":
		visible = true
		is_interactable = true
		return

	var npc_data = get_npc_data()
	if npc_data == null:
		visible = true
		is_interactable = true
		return

	var scene_path := _get_current_scene_path()
	visible = npc_data.is_npc_visible(npc_id, scene_path, GameState.flags)
	is_interactable = npc_data.is_npc_interactable(npc_id, scene_path, GameState.flags)


func _apply_interaction_flags() -> void:
	if npc_id == "":
		return

	var npc_data = get_npc_data()
	if npc_data == null:
		return

	for flag_name in npc_data.get_set_flags_after_interaction(npc_id, _get_current_scene_path(), GameState.flags):
		GameState.set_flag(str(flag_name), true)

func _on_interaction_area_area_entered(area):
	print("AREA ENTERED:", area.name)

	if area.is_in_group("Player"):
		player_inside = true
		player_ref = area.get_parent() as Node2D
		print("PLAYER INSIDE")

func _on_interaction_area_area_exited(area):
	if area.is_in_group("Player"):
		player_inside = false
		player_ref = null


func _on_day_changed(_new_day) -> void:
	_refresh_npc_state()


func _on_time_block_changed(_new_time_block) -> void:
	_refresh_npc_state()


func _get_current_scene_path() -> String:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return ""

	return current_scene.scene_file_path


func get_npc_data():
	return get_node_or_null("/root/NPCData")
