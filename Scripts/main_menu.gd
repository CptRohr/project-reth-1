extends Node

@export_file("*.tscn") var first_scene_path := "res://Areas/Indoor/home.tscn"

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

@onready var start_button: Button = $CanvasLayer/Control/VBoxContainer/StartButton
@onready var settings_button: Button = $CanvasLayer/Control/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CanvasLayer/Control/VBoxContainer/ExitButton
@onready var settings_panel: PanelContainer = $CanvasLayer/Control/SettingsPanel
@onready var resolution_options: OptionButton = $CanvasLayer/Control/SettingsPanel/MarginContainer/VBoxContainer/ResolutionRow/ResolutionOptions
@onready var fullscreen_check: CheckBox = $CanvasLayer/Control/SettingsPanel/MarginContainer/VBoxContainer/FullscreenCheck
@onready var vsync_check: CheckBox = $CanvasLayer/Control/SettingsPanel/MarginContainer/VBoxContainer/VsyncCheck
@onready var status_label: Label = $CanvasLayer/Control/SettingsPanel/MarginContainer/VBoxContainer/StatusLabel
@onready var apply_button: Button = $CanvasLayer/Control/SettingsPanel/MarginContainer/VBoxContainer/ButtonRow/ApplyButton
@onready var back_button: Button = $CanvasLayer/Control/SettingsPanel/MarginContainer/VBoxContainer/ButtonRow/BackButton


func _ready() -> void:
	setup_settings_menu()

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_settings_back_pressed)


func _on_start_pressed() -> void:
	GameState.start_new_game()
	SceneManager.spawn_id = ""
	get_tree().change_scene_to_file(first_scene_path)


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	$CanvasLayer/Control/VBoxContainer.visible = false
	status_label.text = ""


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	$CanvasLayer/Control/VBoxContainer.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func setup_settings_menu() -> void:
	settings_panel.visible = false
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


func _on_apply_pressed() -> void:
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(RESOLUTIONS[resolution_options.selected])
		center_window()

	if vsync_check.button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	status_label.text = "Applied."


func center_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var window_size := DisplayServer.window_get_size()
	var centered_position := screen_position + Vector2i(
		(screen_size.x - window_size.x) >> 1,
		(screen_size.y - window_size.y) >> 1
	)
	DisplayServer.window_set_position(centered_position)
