extends Node

@export_file("*.tscn") var first_scene_path := "res://Areas/Cutscenes/opening_cutscene.tscn"
@export_file("*.tscn") var credits_scene_path := "res://Scene/CreditsMenu.tscn"

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

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	if credits_button:
		credits_button.pressed.connect(_on_credits_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	sound_apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_settings_back_pressed)
	resolution_tab.pressed.connect(_show_resolution_settings)
	sound_tab.pressed.connect(_show_sound_settings)
	controls_tab.pressed.connect(_show_controls_settings)
	reset_button.pressed.connect(_on_reset_to_default_pressed)
	master_volume_slider.value_changed.connect(_on_audio_slider_changed)
	sfx_volume_slider.value_changed.connect(_on_audio_slider_changed)
	music_volume_slider.value_changed.connect(_on_audio_slider_changed)

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(credits_scene_path)


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


func close_settings() -> void:
	if not settings_panel.visible:
		return

	animation_player.play_backwards("SettingsPanel")
	await animation_player.animation_finished
	settings_panel.visible = false


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


func _show_sound_settings() -> void:
	_set_settings_section(sound_section)


func _show_controls_settings() -> void:
	_set_settings_section(controls_section)


func _set_settings_section(active_section: Control) -> void:
	resolution_section.visible = active_section == resolution_section
	sound_section.visible = active_section == sound_section
	controls_section.visible = active_section == controls_section

	resolution_tab.button_pressed = active_section == resolution_section
	sound_tab.button_pressed = active_section == sound_section
	controls_tab.button_pressed = active_section == controls_section
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
