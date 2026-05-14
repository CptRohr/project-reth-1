extends CanvasLayer

const MAIN_MENU_SCENE := "res://Scene/MainMenu.tscn"
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var root_control: Control
var root_panel: PanelContainer
var main_row: HBoxContainer
var settings_box: VBoxContainer
var calendar_box: VBoxContainer
var calendar_month_label: Label
var calendar_grid: GridContainer
var resolution_options: OptionButton
var fullscreen_check: CheckBox
var vsync_check: CheckBox
var status_label: Label


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_pause_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and not _is_main_menu():
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
	main_row.visible = true
	settings_box.visible = false
	calendar_box.visible = false
	status_label.text = ""


func hide_pause_menu() -> void:
	get_tree().paused = false
	root_control.visible = false


func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center_container)

	root_panel = PanelContainer.new()
	root_panel.custom_minimum_size = Vector2(760, 420)
	center_container.add_child(root_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	root_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)

	main_row = HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 8)
	stack.add_child(main_row)

	_add_button(main_row, "Resume", hide_pause_menu)
	_add_button(main_row, "Calendar", _show_calendar)
	_add_button(main_row, "Settings", _show_settings)
	_add_button(main_row, "Main Menu", _go_to_main_menu)
	_add_button(main_row, "Quit Game", Callable(get_tree(), "quit"))

	settings_box = VBoxContainer.new()
	settings_box.add_theme_constant_override("separation", 8)
	stack.add_child(settings_box)

	var resolution_row := HBoxContainer.new()
	resolution_row.add_theme_constant_override("separation", 8)
	settings_box.add_child(resolution_row)

	var resolution_label := Label.new()
	resolution_label.text = "Resolution"
	resolution_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolution_row.add_child(resolution_label)

	resolution_options = OptionButton.new()
	resolution_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolution_row.add_child(resolution_options)

	fullscreen_check = CheckBox.new()
	fullscreen_check.text = "Fullscreen"
	settings_box.add_child(fullscreen_check)

	vsync_check = CheckBox.new()
	vsync_check.text = "VSync"
	settings_box.add_child(vsync_check)

	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(0, 20)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(status_label)

	var settings_buttons := HBoxContainer.new()
	settings_buttons.add_theme_constant_override("separation", 8)
	settings_box.add_child(settings_buttons)

	_add_button(settings_buttons, "Apply", _apply_settings)
	_add_button(settings_buttons, "Back", _show_main_buttons)

	_build_calendar_ui(stack)
	_setup_settings_values()


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_settings() -> void:
	main_row.visible = false
	calendar_box.visible = false
	settings_box.visible = true
	status_label.text = ""
	_setup_settings_values()


func _show_main_buttons() -> void:
	main_row.visible = true
	settings_box.visible = false
	calendar_box.visible = false


func _show_calendar() -> void:
	main_row.visible = false
	settings_box.visible = false
	calendar_box.visible = true
	_refresh_calendar_view()


func _build_calendar_ui(parent: Control) -> void:
	calendar_box = VBoxContainer.new()
	calendar_box.add_theme_constant_override("separation", 8)
	parent.add_child(calendar_box)

	calendar_month_label = Label.new()
	calendar_month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	calendar_box.add_child(calendar_month_label)

	calendar_grid = GridContainer.new()
	calendar_grid.columns = 7
	calendar_box.add_child(calendar_grid)

	var calendar_buttons := HBoxContainer.new()
	calendar_buttons.add_theme_constant_override("separation", 8)
	calendar_box.add_child(calendar_buttons)

	_add_button(calendar_buttons, "Back", _show_main_buttons)
	calendar_box.visible = false


func _refresh_calendar_view() -> void:
	for child in calendar_grid.get_children():
		child.queue_free()

	var calendar_manager = get_node("/root/CalendarManager")
	var date_info: Dictionary = calendar_manager.get_date_info(GameState.calendar_day_index)
	var month := int(date_info["month"])
	calendar_month_label.text = "%s %s" % [date_info["month_name"], calendar_manager.STORY_YEAR]

	for weekday in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
		var header := Label.new()
		header.text = weekday
		header.custom_minimum_size = Vector2(96, 24)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		calendar_grid.add_child(header)

	for cell in calendar_manager.get_month_grid(month, GameState.calendar_day_index):
		var label := Label.new()
		label.custom_minimum_size = Vector2(96, 48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		if cell.is_empty():
			label.text = ""
		else:
			label.text = "%s\n%s" % [cell["day"], cell["routine"]]

			if bool(cell["is_today"]):
				label.add_theme_color_override("font_color", Color.YELLOW)

		calendar_grid.add_child(label)


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


func _is_main_menu() -> bool:
	var current_scene := get_tree().current_scene
	return current_scene != null and current_scene.scene_file_path == MAIN_MENU_SCENE
