extends CanvasLayer

const MAIN_MENU_SCENE := "res://Scene/MainMenu.tscn"
const OPENING_CUTSCENE_SCENE := "res://Areas/Cutscenes/opening_cutscene.tscn"
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

@onready var root_control: Control = $RootControl
@onready var main_view: Control = $RootControl/MainView
@onready var clock: PauseMenuClock = $RootControl/MainView/ClockPanel/Clock
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var settings_button: Button = $RootControl/MainView/SettingsButton
@onready var calendar_button: Button = $RootControl/MainView/CalendarButton
@onready var stats_button: Button = $RootControl/MainView/StatsButton
@onready var resume_button: Button = $RootControl/MainView/ResumeButton
@onready var main_menu_button: Button = $RootControl/MainView/MainMenuButton
@onready var quit_button: Button = $RootControl/MainView/QuitButton

@onready var stats_panel: Control = $RootControl/StatsPanel
@onready var stats_grid: GridContainer = $RootControl/StatsPanel/Margin/VBox/StatsGrid
@onready var stats_back_button: Button = $RootControl/StatsPanel/Margin/VBox/StatsBackButton

@onready var settings_panel: Control = $RootControl/SettingsPanel
@onready var resolution_options: OptionButton = $RootControl/SettingsPanel/Margin/VBox/ResolutionRow/ResolutionOptions
@onready var fullscreen_check: CheckBox = $RootControl/SettingsPanel/Margin/VBox/FullscreenCheck
@onready var vsync_check: CheckBox = $RootControl/SettingsPanel/Margin/VBox/VsyncCheck
@onready var master_volume_slider: HSlider = $RootControl/SettingsPanel/Margin/VBox/MasterVolumeRow/MasterVolumeSlider
@onready var master_volume_value: Label = $RootControl/SettingsPanel/Margin/VBox/MasterVolumeRow/MasterVolumeValue
@onready var sfx_volume_slider: HSlider = $RootControl/SettingsPanel/Margin/VBox/SfxVolumeRow/SfxVolumeSlider
@onready var sfx_volume_value: Label = $RootControl/SettingsPanel/Margin/VBox/SfxVolumeRow/SfxVolumeValue
@onready var music_volume_slider: HSlider = $RootControl/SettingsPanel/Margin/VBox/MusicVolumeRow/MusicVolumeSlider
@onready var music_volume_value: Label = $RootControl/SettingsPanel/Margin/VBox/MusicVolumeRow/MusicVolumeValue
@onready var status_label: Label = $RootControl/SettingsPanel/Margin/VBox/StatusLabel
@onready var apply_button: Button = $RootControl/SettingsPanel/Margin/VBox/ButtonsRow/ApplyButton
@onready var settings_back_button: Button = $RootControl/SettingsPanel/Margin/VBox/ButtonsRow/SettingsBackButton

@onready var calendar_panel: Control = $RootControl/CalendarPanel
@onready var calendar_month_label: Label = $RootControl/CalendarPanel/Margin/VBox/CalendarMonthLabel
@onready var calendar_grid: GridContainer = $RootControl/CalendarPanel/Margin/VBox/CalendarGrid
@onready var previous_button: Button = $RootControl/CalendarPanel/Margin/VBox/ButtonsRow/PreviousButton
@onready var today_button: Button = $RootControl/CalendarPanel/Margin/VBox/ButtonsRow/TodayButton
@onready var next_button: Button = $RootControl/CalendarPanel/Margin/VBox/ButtonsRow/NextButton
@onready var calendar_back_button: Button = $RootControl/CalendarPanel/Margin/VBox/ButtonsRow/CalendarBackButton

var _focused_button: Button = null
var calendar_view_month: int = 4

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_buttons()
	_setup_settings_values()
	root_control.visible = false
	get_tree().paused = false
	animation_player.stop(true)

func _process(_delta: float) -> void:
	if root_control.visible:
		_update_clock()
		_update_selector_hand()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and not _is_non_pause_scene():
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if root_control.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not main_view.visible:
			_show_main_view()
		else:
			hide_pause_menu()

func toggle_pause_menu() -> void:
	if root_control.visible:
		hide_pause_menu()
	else:
		show_pause_menu()

func show_pause_menu() -> void:
	get_tree().paused = true
	root_control.visible = true
	animation_player.play("pause_menu_in_out")
	_show_main_view()

func hide_pause_menu() -> void:
	animation_player.play_backwards("pause_menu_in_out")
	await animation_player.animation_finished
	get_tree().paused = false
	root_control.visible = false

func _connect_buttons() -> void:
	_setup_button(settings_button, _show_settings_panel)
	_setup_button(calendar_button, _show_calendar_panel)
	_setup_button(stats_button, _show_stats_panel)
	_setup_button(resume_button, hide_pause_menu)
	_setup_button(main_menu_button, _go_to_main_menu)
	_setup_button(quit_button, Callable(get_tree(), "quit"))

	stats_back_button.pressed.connect(_show_main_view)
	settings_back_button.pressed.connect(_show_main_view)
	calendar_back_button.pressed.connect(_show_main_view)

	apply_button.pressed.connect(_apply_settings)
	previous_button.pressed.connect(_show_previous_month)
	today_button.pressed.connect(_show_current_month)
	next_button.pressed.connect(_show_next_month)

	master_volume_slider.value_changed.connect(_on_audio_slider_changed)
	sfx_volume_slider.value_changed.connect(_on_audio_slider_changed)
	music_volume_slider.value_changed.connect(_on_audio_slider_changed)

func _setup_button(button: Button, on_pressed_callable: Callable) -> void:
	button.pressed.connect(on_pressed_callable)
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(func():
		_focused_button = button
	)
	button.focus_exited.connect(func():
		if _focused_button == button:
			_focused_button = null
	)
	button.mouse_entered.connect(func(): button.grab_focus())

func _show_main_view() -> void:
	main_view.visible = true
	stats_panel.visible = false
	settings_panel.visible = false
	calendar_panel.visible = false
	resume_button.grab_focus()

func _show_stats_panel() -> void:
	main_view.visible = false
	stats_panel.visible = true
	_refresh_stats_view()
	stats_back_button.grab_focus()

func _show_settings_panel() -> void:
	main_view.visible = false
	settings_panel.visible = true
	status_label.text = ""
	_setup_settings_values()
	settings_back_button.grab_focus()

func _show_calendar_panel() -> void:
	main_view.visible = false
	calendar_panel.visible = true
	calendar_view_month = int(get_calendar_manager().get_date_info(GameState.calendar_day_index)["month"])
	_refresh_calendar_view()
	calendar_back_button.grab_focus()

func _update_clock() -> void:
	var time_dict: Dictionary = Time.get_time_dict_from_system()
	var hour: int = int(time_dict.get("hour", 0))
	var minute: int = int(time_dict.get("minute", 0))
	var second: int = int(time_dict.get("second", 0))
	var hour_fraction: float = float(hour % 12) + float(minute) / 60.0 + float(second) / 3600.0
	var minute_fraction: float = float(minute) + float(second) / 60.0
	clock.set_hour_angle(hour_fraction * TAU / 12.0 - PI / 2.0)
	clock.set_minute_angle(minute_fraction * TAU / 60.0 - PI / 2.0)

func _update_selector_hand() -> void:
	var target: Button = _focused_button
	if target == null:
		target = resume_button
	var clock_center: Vector2 = clock.global_position + clock.size * 0.5
	var target_center: Vector2 = target.global_position + target.size * 0.5
	clock.set_selector_angle((target_center - clock_center).angle())

func _refresh_stats_view() -> void:
	for child in stats_grid.get_children():
		child.queue_free()
	var player_stats: Dictionary = GameState.get_player_stats()
	for stat_name in GameState.PLAYER_STATS:
		var name_label := Label.new()
		name_label.text = str(stat_name)
		name_label.custom_minimum_size = Vector2(200, 28)
		stats_grid.add_child(name_label)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(100, 28)
		if stat_name == GameState.ENERGY_STAT:
			value_label.text = "%s / %s" % [player_stats[stat_name], GameState.DEFAULT_ENERGY]
		else:
			value_label.text = "%s / %s" % [player_stats[stat_name], GameState.STAT_MAX]
		stats_grid.add_child(value_label)

func _setup_settings_values() -> void:
	resolution_options.clear()
	for res in RESOLUTIONS:
		resolution_options.add_item("%sx%s" % [res.x, res.y])
	var cur_res := DisplayServer.window_get_size()
	var idx := RESOLUTIONS.find(cur_res)
	resolution_options.select(idx if idx != -1 else 0)
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	master_volume_slider.value = AudioSettings.get_volume_percent(AudioSettings.MASTER_BUS)
	sfx_volume_slider.value = AudioSettings.get_volume_percent(AudioSettings.SFX_BUS)
	music_volume_slider.value = AudioSettings.get_volume_percent(AudioSettings.MUSIC_BUS)
	_update_audio_volume_labels()

func _apply_settings() -> void:
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(RESOLUTIONS[resolution_options.selected])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_check.button_pressed else DisplayServer.VSYNC_DISABLED)
	AudioSettings.set_volume_percent(AudioSettings.MASTER_BUS, master_volume_slider.value, true)
	AudioSettings.set_volume_percent(AudioSettings.SFX_BUS, sfx_volume_slider.value, true)
	AudioSettings.set_volume_percent(AudioSettings.MUSIC_BUS, music_volume_slider.value, true)
	status_label.text = "Applied."

func _on_audio_slider_changed(_v: float) -> void:
	_update_audio_volume_labels()

func _update_audio_volume_labels() -> void:
	master_volume_value.text = str(int(master_volume_slider.value))
	sfx_volume_value.text = str(int(sfx_volume_slider.value))
	music_volume_value.text = str(int(music_volume_slider.value))

func _show_previous_month() -> void:
	calendar_view_month = _get_wrapped_month(-1)
	_refresh_calendar_view()

func _show_next_month() -> void:
	calendar_view_month = _get_wrapped_month(1)
	_refresh_calendar_view()

func _show_current_month() -> void:
	calendar_view_month = int(get_calendar_manager().get_date_info(GameState.calendar_day_index)["month"])
	_refresh_calendar_view()

func _get_wrapped_month(dir: int) -> int:
	var story_months: Array = get_calendar_manager().get_story_months()
	var idx := story_months.find(calendar_view_month)
	if idx == -1:
		return int(get_calendar_manager().get_date_info(GameState.calendar_day_index)["month"])
	return int(story_months[(idx + dir + story_months.size()) % story_months.size()])

func _refresh_calendar_view() -> void:
	for child in calendar_grid.get_children():
		child.queue_free()
	var cm = get_calendar_manager()
	var view_info = cm.get_date_info(cm.parse_date_key("%02d/01" % calendar_view_month))
	calendar_month_label.text = "%s %s" % [view_info["month_name"], cm.STORY_YEAR]
	for wd in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
		var h := Label.new()
		h.text = wd
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		calendar_grid.add_child(h)
	for cell in cm.get_month_grid(calendar_view_month, GameState.calendar_day_index):
		var l := Label.new()
		l.custom_minimum_size = Vector2(90, 60)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if cell.is_empty():
			l.text = ""
		else:
			l.text = str(cell["day"]) + "\n" + str(cell["routine"])
			if bool(cell["is_today"]):
				l.add_theme_color_override("font_color", Color.YELLOW)
		calendar_grid.add_child(l)

func get_calendar_manager():
	return get_node("/root/CalendarManager")

func _go_to_main_menu() -> void:
	hide_pause_menu()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _is_non_pause_scene() -> bool:
	var cur = get_tree().current_scene
	return cur != null and [MAIN_MENU_SCENE, OPENING_CUTSCENE_SCENE].has(cur.scene_file_path)
