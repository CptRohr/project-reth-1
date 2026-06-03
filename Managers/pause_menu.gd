extends CanvasLayer

const MAIN_MENU_SCENE := "res://Scene/MainMenu.tscn"
const OPENING_CUTSCENE_SCENE := "res://Areas/Cutscenes/opening_cutscene.tscn"
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

@onready var root_control: Control = $RootControl
@onready var main_row: HBoxContainer = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow
@onready var stats_box: VBoxContainer = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/StatsBox
@onready var stats_grid: GridContainer = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/StatsBox/StatsGrid
@onready var settings_box: VBoxContainer = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox
@onready var resolution_options: OptionButton = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox/ResolutionRow/ResolutionOptions
@onready var fullscreen_check: CheckBox = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox/FullscreenCheck
@onready var vsync_check: CheckBox = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox/VsyncCheck
@onready var status_label: Label = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox/StatusLabel
@onready var calendar_box: VBoxContainer = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox
@onready var calendar_month_label: Label = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox/CalendarMonthLabel
@onready var calendar_grid: GridContainer = $RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox/CalendarGrid

var calendar_view_month := 4


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_buttons()
	_setup_settings_values()
	hide_pause_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and not _is_non_pause_scene():
		toggle_pause_menu()
		get_viewport().set_input_as_handled()


func toggle_pause_menu() -> void:
	if root_control.visible:
		hide_pause_menu()
	else:
		show_pause_menu()


func show_pause_menu() -> void:
	get_tree().paused = true
	root_control.visible = true
	_show_main_buttons()
	status_label.text = ""


func hide_pause_menu() -> void:
	get_tree().paused = false
	root_control.visible = false


func _connect_buttons() -> void:
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow/ResumeButton.pressed.connect(hide_pause_menu)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow/StatsButton.pressed.connect(_show_stats)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow/CalendarButton.pressed.connect(_show_calendar)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow/SettingsButton.pressed.connect(_show_settings)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow/MainMenuButton.pressed.connect(_go_to_main_menu)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/MainRow/QuitButton.pressed.connect(Callable(get_tree(), "quit"))
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/StatsBox/StatsButtons/StatsBackButton.pressed.connect(_show_main_buttons)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox/SettingsButtons/ApplyButton.pressed.connect(_apply_settings)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/SettingsBox/SettingsButtons/SettingsBackButton.pressed.connect(_show_main_buttons)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox/CalendarButtons/PreviousButton.pressed.connect(_show_previous_month)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox/CalendarButtons/TodayButton.pressed.connect(_show_current_month)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox/CalendarButtons/NextButton.pressed.connect(_show_next_month)
	$RootControl/CenterContainer/RootPanel/MarginContainer/Stack/CalendarBox/CalendarButtons/CalendarBackButton.pressed.connect(_show_main_buttons)


func _show_stats() -> void:
	main_row.visible = false
	stats_box.visible = true
	settings_box.visible = false
	calendar_box.visible = false
	_refresh_stats_view()


func _show_settings() -> void:
	main_row.visible = false
	stats_box.visible = false
	calendar_box.visible = false
	settings_box.visible = true
	status_label.text = ""
	_setup_settings_values()


func _show_main_buttons() -> void:
	main_row.visible = true
	stats_box.visible = false
	settings_box.visible = false
	calendar_box.visible = false


func _show_calendar() -> void:
	main_row.visible = false
	stats_box.visible = false
	settings_box.visible = false
	calendar_box.visible = true
	calendar_view_month = int(get_calendar_manager().get_date_info(GameState.calendar_day_index)["month"])
	_refresh_calendar_view()


func _refresh_stats_view() -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	var player_stats: Dictionary = GameState.get_player_stats()

	for stat_name in GameState.PLAYER_STATS:
		var name_label := Label.new()
		name_label.text = str(stat_name)
		name_label.custom_minimum_size = Vector2(240, 28)
		stats_grid.add_child(name_label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(160, 28)

		if stat_name == GameState.ENERGY_STAT:
			value_label.text = "%s / %s" % [player_stats[stat_name], GameState.DEFAULT_ENERGY]
		else:
			value_label.text = "%s / %s" % [player_stats[stat_name], GameState.STAT_MAX]

		stats_grid.add_child(value_label)


func _show_previous_month() -> void:
	calendar_view_month = get_wrapped_story_month(-1)
	_refresh_calendar_view()


func _show_next_month() -> void:
	calendar_view_month = get_wrapped_story_month(1)
	_refresh_calendar_view()


func _show_current_month() -> void:
	calendar_view_month = int(get_calendar_manager().get_date_info(GameState.calendar_day_index)["month"])
	_refresh_calendar_view()


func get_wrapped_story_month(direction: int) -> int:
	var calendar_manager = get_calendar_manager()
	var story_months: Array = calendar_manager.get_story_months()
	var current_index := story_months.find(calendar_view_month)

	if current_index == -1:
		return int(get_calendar_manager().get_date_info(GameState.calendar_day_index)["month"])

	var next_index := (current_index + direction) % story_months.size()

	if next_index < 0:
		next_index = story_months.size() - 1

	return int(story_months[next_index])


func _refresh_calendar_view() -> void:
	for child in calendar_grid.get_children():
		child.queue_free()

	var calendar_manager = get_calendar_manager()
	var current_date_info: Dictionary = calendar_manager.get_date_info(GameState.calendar_day_index)
	var view_date_info: Dictionary = calendar_manager.get_date_info(calendar_manager.parse_date_key("%02d/01" % calendar_view_month))
	var month := calendar_view_month
	calendar_month_label.text = "%s %s" % [view_date_info["month_name"], calendar_manager.STORY_YEAR]

	for weekday in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
		var header := Label.new()
		header.text = weekday
		header.custom_minimum_size = Vector2(96, 24)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		calendar_grid.add_child(header)

	for cell in calendar_manager.get_month_grid(month, GameState.calendar_day_index):
		var label := Label.new()
		label.custom_minimum_size = Vector2(96, 72)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		if cell.is_empty():
			label.text = ""
		else:
			label.text = "%s\n%s" % [cell["day"], cell["routine"]]

			if bool(cell.get("has_plan", false)) and str(cell.get("plan_summary", "")) != "":
				label.text += "\n* %s" % cell["plan_summary"]

			if bool(cell.get("has_special_events", false)):
				label.text += "\n! %s" % cell["special_event_summary"]
				label.add_theme_color_override("font_color", Color.ORANGE)

			if bool(cell["is_today"]):
				label.add_theme_color_override("font_color", Color.YELLOW)
			elif int(current_date_info["month"]) != month:
				label.add_theme_color_override("font_color", Color.LIGHT_GRAY)

		calendar_grid.add_child(label)


func get_calendar_manager():
	return get_node("/root/CalendarManager")


func _setup_settings_values() -> void:
	resolution_options.clear()

	for resolution in RESOLUTIONS:
		resolution_options.add_item("%sx%s" % [resolution.x, resolution.y])

	var current_size := DisplayServer.window_get_size()
	var current_index := RESOLUTIONS.find(current_size)
	if current_index == -1:
		current_index = 0

	resolution_options.select(current_index)
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED


func _apply_settings() -> void:
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(RESOLUTIONS[resolution_options.selected])
		_center_window()

	if vsync_check.button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	status_label.text = "Applied."


func _go_to_main_menu() -> void:
	hide_pause_menu()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _center_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var window_size := DisplayServer.window_get_size()
	var centered_position := screen_position + Vector2i(
		(screen_size.x - window_size.x) >> 1,
		(screen_size.y - window_size.y) >> 1
	)
	DisplayServer.window_set_position(centered_position)


func _is_non_pause_scene() -> bool:
	var current_scene := get_tree().current_scene
	return current_scene != null and [MAIN_MENU_SCENE, OPENING_CUTSCENE_SCENE].has(current_scene.scene_file_path)
