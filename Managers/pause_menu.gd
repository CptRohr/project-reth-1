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
	root_panel.custom_minimum_size = Vector2(680, 160)
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
	settings_box.visible = true
	status_label.text = ""
	_setup_settings_values()


func _show_main_buttons() -> void:
	main_row.visible = true
	settings_box.visible = false


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
