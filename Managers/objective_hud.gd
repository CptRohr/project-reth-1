extends CanvasLayer

const HIDDEN_SCENES := [
	"res://Scene/BootScene.tscn",
	"res://Scene/MainMenu.tscn",
	"res://Areas/Cutscenes/opening_cutscene.tscn",
]

@onready var panel := PanelContainer.new()
@onready var label := Label.new()


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_connect_state_signals()
	_update_objective()


func _build_ui() -> void:
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = 14
	panel.offset_bottom = 76
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	margin.add_child(label)

	add_child(panel)


func _connect_state_signals() -> void:
	if not GameState.state_changed.is_connected(_update_objective):
		GameState.state_changed.connect(_update_objective)

	if not GameState.day_changed.is_connected(_on_day_changed):
		GameState.day_changed.connect(_on_day_changed)

	if not GameState.time_block_changed.is_connected(_on_time_block_changed):
		GameState.time_block_changed.connect(_on_time_block_changed)

	if not GameState.state_loaded.is_connected(_update_objective):
		GameState.state_loaded.connect(_update_objective)


func _update_objective() -> void:
	panel.visible = not _is_hidden_scene()

	if not panel.visible:
		return

	var calendar_manager = get_node_or_null("/root/CalendarManager")

	if calendar_manager == null:
		label.text = "Objective: Explore"
		return

	label.text = "Objective: %s" % calendar_manager.get_current_objective_text()


func _on_day_changed(_new_day) -> void:
	_update_objective()


func _on_time_block_changed(_new_time_block) -> void:
	_update_objective()


func _process(_delta: float) -> void:
	_update_objective()


func _is_hidden_scene() -> bool:
	var current_scene := get_tree().current_scene
	return current_scene != null and HIDDEN_SCENES.has(current_scene.scene_file_path)
