extends Node

@export_file("*.tscn") var first_scene_path := "res://Areas/Cutscenes/opening_cutscene.tscn"

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const SETTINGS_PANEL_BASE_SIZE := Vector2(1280.0, 720.0)

@onready var rethorizon_label: Label = $CanvasLayer/MenuMainContainer/VBoxContainer/RETHorizonPresent
@onready var subtitle_label: Label = $CanvasLayer/MenuMainContainer/VBoxContainer/Subtitle
@onready var version_label: Label = $CanvasLayer/MenuMainContainer/VersionLabel
@onready var godot_label: Label = $CanvasLayer/MenuMainContainer/GodotEngineLabel
@onready var credits_button: Button = $CanvasLayer/MenuMainContainer/CreditsButton
@onready var credits_panel: Control = $CanvasLayer/MenuMainContainer/CreditsPanel
@onready var credits_back_button: Button = $CanvasLayer/MenuMainContainer/CreditsPanel/BackButton
@onready var start_button: Button = $CanvasLayer/MenuMainContainer/StartButton
@onready var settings_button: Button = $CanvasLayer/MenuMainContainer/SettingsButton
@onready var quit_button: Button = $CanvasLayer/MenuMainContainer/ExitButton
@onready var settings_panel: Control = $CanvasLayer/MenuMainContainer/SettingsPanel
@onready var animation_player: AnimationPlayer = $CanvasLayer/AnimationPlayer
@onready var resolution_section: Control = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/ResolutionSection
@onready var sound_section: Control = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection
@onready var controls_section: Control = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/ControlsSection
@onready var resolution_options: OptionButton = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/ResolutionSection/ResolutionOptions
@onready var fullscreen_check: CheckBox = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/ResolutionSection/FullscreenCheck
@onready var vsync_check: CheckBox = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/ResolutionSection/VsyncCheck
@onready var master_volume_slider: HSlider = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/MasterVolumeRow/MasterVolumeSlider
@onready var master_volume_value: Label = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/MasterVolumeRow/MasterVolumeValue
@onready var sfx_volume_slider: HSlider = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/SfxVolumeRow/SfxVolumeSlider
@onready var sfx_volume_value: Label = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/SfxVolumeRow/SfxVolumeValue
@onready var music_volume_slider: HSlider = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/MusicVolumeRow/MusicVolumeSlider
@onready var music_volume_value: Label = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/MusicVolumeRow/MusicVolumeValue
@onready var status_label: Label = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/StatusLabel
@onready var apply_button: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/ResolutionSection/ApplyButton
@onready var sound_apply_button: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/LeftContent/SoundSection/SoundApplyButton
@onready var back_button: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/CloseButton
@onready var resolution_tab: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/RightTabs/ResolutionTab
@onready var sound_tab: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/RightTabs/SoundTab
@onready var controls_tab: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/RightTabs/ControlsTab
@onready var reset_button: Button = $CanvasLayer/MenuMainContainer/SettingsPanel/ResetButton


func _ready() -> void:
	setup_settings_menu()
	_update_settings_panel_scale()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_update_settings_panel_scale)

	# Main Menu Buttons
	_setup_main_menu_button(start_button, _on_start_pressed, settings_button.get_path(), quit_button.get_path())
	_setup_main_menu_button(settings_button, _on_settings_pressed, quit_button.get_path(), start_button.get_path(), start_button.get_path())
	_setup_main_menu_button(quit_button, _on_quit_pressed, start_button.get_path(), settings_button.get_path(), settings_button.get_path())
	if credits_button:
		_setup_main_menu_button(credits_button, _on_credits_pressed)
	_setup_main_menu_button(credits_back_button, _on_credits_back_pressed)

	# Settings Panel Buttons
	_setup_settings_button(apply_button, _on_apply_pressed)
	_setup_settings_button(sound_apply_button, _on_apply_pressed)
	_setup_settings_button(back_button, _on_settings_back_pressed)
	_setup_settings_button(resolution_tab, _show_resolution_settings)
	_setup_settings_button(sound_tab, _show_sound_settings)
	_setup_settings_button(controls_tab, _show_controls_settings)
	_setup_settings_button(reset_button, _on_reset_to_default_pressed)

	# Initial focus
	GamepadFocusOverlay.push_focus(start_button)

	master_volume_slider.value_changed.connect(_on_audio_slider_changed)
	sfx_volume_slider.value_changed.connect(_on_audio_slider_changed)
	music_volume_slider.value_changed.connect(_on_audio_slider_changed)


func _setup_main_menu_button(button: Button, on_pressed_callable: Callable, focus_next: NodePath = NodePath(""), focus_prev: NodePath = NodePath(""), focus_other_row: NodePath = NodePath("")):
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(on_pressed_callable)
	button.focus_neighbor_bottom = focus_next
	button.focus_neighbor_top = focus_prev
	button.focus_neighbor_left = focus_other_row
	button.focus_neighbor_right = focus_other_row

func _setup_settings_button(button: Button, on_pressed_callable: Callable, focus_right_name: NodePath = NodePath(""), focus_left_name: NodePath = NodePath(""), focus_up_name: NodePath = NodePath(""), focus_down_name: NodePath = NodePath("")):
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(on_pressed_callable)
	if focus_right_name != NodePath(""):
		button.focus_neighbor_right = focus_right_name
	if focus_left_name != NodePath(""):
		button.focus_neighbor_left = focus_left_name
	if focus_up_name != NodePath(""):
		button.focus_neighbor_up = focus_up_name
	if focus_down_name != NodePath(""):
		button.focus_neighbor_down = focus_down_name

func _on_credits_pressed() -> void:
	credits_panel.visible = true
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("creditspanel")
	GamepadFocusOverlay.push_focus(credits_back_button)


func _on_credits_back_pressed() -> void:
	animation_player.play_backwards("creditspanel")
	await animation_player.animation_finished
	credits_panel.visible = false
	GamepadFocusOverlay.pop_focus()


func _on_start_pressed() -> void:
	GameState.start_new_game()
	SceneManager.spawn_id = ""
	get_tree().change_scene_to_file(first_scene_path)


func open_settings() -> void:
	_update_settings_panel_scale()
	settings_panel.visible = true
	_show_resolution_settings()
	status_label.text = ""
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("SettingsPanel")
	_set_main_menu_focus_mode(Control.FOCUS_NONE)
	resolution_tab.grab_focus()
	resolution_options.grab_focus()


func close_settings() -> void:
	if not settings_panel.visible:
		return

	animation_player.play_backwards("SettingsPanel")
	await animation_player.animation_finished
	settings_panel.visible = false
	_set_main_menu_focus_mode(Control.FOCUS_ALL)
	settings_button.grab_focus()


func _update_settings_panel_scale() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_x := viewport_size.x / SETTINGS_PANEL_BASE_SIZE.x
	var scale_y := viewport_size.y / SETTINGS_PANEL_BASE_SIZE.y
	settings_panel.scale = Vector2(scale_x, scale_y)
	settings_panel.pivot_offset = settings_panel.size / 2.0


func _on_settings_pressed() -> void:
	open_settings()


func _on_settings_back_pressed() -> void:
	close_settings()


func _on_quit_pressed() -> void:
	get_tree().quit()


func setup_settings_menu() -> void:
	settings_panel.visible = false
	_show_resolution_settings()
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
	_setup_audio_settings_values()


func _show_resolution_settings() -> void:
	_set_settings_section(resolution_section)
	resolution_tab.grab_focus()
	resolution_options.grab_focus()
	_set_settings_focus_mode(Control.FOCUS_ALL)
	_set_main_menu_focus_mode(Control.FOCUS_NONE)


func _show_sound_settings() -> void:
	_set_settings_section(sound_section)
	sound_tab.grab_focus()
	master_volume_slider.grab_focus()
	_set_settings_focus_mode(Control.FOCUS_ALL)
	_set_main_menu_focus_mode(Control.FOCUS_NONE)


func _show_controls_settings() -> void:
	_set_settings_section(controls_section)
	controls_tab.grab_focus()
	_set_settings_focus_mode(Control.FOCUS_ALL)
	_set_main_menu_focus_mode(Control.FOCUS_NONE)
	# TODO: Add focus for controls section once implemented


func _set_settings_section(active_section: Control) -> void:
	resolution_section.visible = active_section == resolution_section
	sound_section.visible = active_section == sound_section
	controls_section.visible = active_section == controls_section

	resolution_tab.button_pressed = active_section == resolution_section
	sound_tab.button_pressed = active_section == sound_section
	controls_tab.button_pressed = active_section == controls_section


func _set_main_menu_focus_mode(mode: int) -> void:
	start_button.focus_mode = mode
	settings_button.focus_mode = mode
	quit_button.focus_mode = mode
	if credits_button:
		credits_button.focus_mode = mode


func _set_settings_focus_mode(mode: int) -> void:
	resolution_options.focus_mode = mode
	fullscreen_check.focus_mode = mode
	vsync_check.focus_mode = mode
	master_volume_slider.focus_mode = mode
	sfx_volume_slider.focus_mode = mode
	music_volume_slider.focus_mode = mode
	apply_button.focus_mode = mode
	sound_apply_button.focus_mode = mode
	back_button.focus_mode = mode
	resolution_tab.focus_mode = mode
	sound_tab.focus_mode = mode
	controls_tab.focus_mode = mode
	reset_button.focus_mode = mode


func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_settings()
	status_label.text = ""


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

	_apply_audio_settings()
	status_label.text = "Applied."


func _on_reset_to_default_pressed() -> void:
	var default_index := RESOLUTIONS.find(Vector2i(1920, 1080))
	if default_index == -1:
		default_index = RESOLUTIONS.size() - 1

	resolution_options.select(default_index)
	fullscreen_check.button_pressed = false
	vsync_check.button_pressed = true
	master_volume_slider.value = 100.0
	sfx_volume_slider.value = 100.0
	music_volume_slider.value = 100.0
	_update_audio_volume_labels()
	status_label.text = "Defaults ready. Press Apply."


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


func _setup_audio_settings_values() -> void:
	master_volume_slider.value = AudioSettings.get_volume_percent(AudioSettings.MASTER_BUS)
	sfx_volume_slider.value = AudioSettings.get_volume_percent(AudioSettings.SFX_BUS)
	music_volume_slider.value = AudioSettings.get_volume_percent(AudioSettings.MUSIC_BUS)
	_update_audio_volume_labels()


func _on_audio_slider_changed(_value: float) -> void:
	_update_audio_volume_labels()


func _update_audio_volume_labels() -> void:
	master_volume_value.text = "%s" % int(master_volume_slider.value)
	sfx_volume_value.text = "%s" % int(sfx_volume_slider.value)
	music_volume_value.text = "%s" % int(music_volume_slider.value)


func _apply_audio_settings() -> void:
	AudioSettings.set_volume_percent(AudioSettings.MASTER_BUS, master_volume_slider.value, false)
	AudioSettings.set_volume_percent(AudioSettings.SFX_BUS, sfx_volume_slider.value, false)
	AudioSettings.set_volume_percent(AudioSettings.MUSIC_BUS, music_volume_slider.value, false)
	AudioSettings.save_settings()
