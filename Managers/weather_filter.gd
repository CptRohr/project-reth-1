extends CanvasLayer

const RAIN_WEATHERS := ["rain", "thunderstorm"]

@export var weather_layer := 2
@export var outdoor_scene_paths: PackedStringArray = [
	"res://Areas/street.tscn",
	"res://Areas/street2.tscn",
	"res://Areas/street3.tscn",
]
@export var outdoor_scene_prefixes: PackedStringArray = []
@export var indoor_audio_scene_paths: PackedStringArray = []
@export var indoor_audio_scene_prefixes: PackedStringArray = [
	"res://Areas/Indoor/",
]
@export_group("Rain")
@export var rain_line_count := 70
@export var rain_speed := 620.0
@export var rain_angle_degrees := 105.0
@export var rain_line_length := 38.0
@export var rain_line_width := 1.25
@export var rain_color := Color(0.72, 0.84, 1.0, 0.42)
@export_group("Thunderstorm Rain")
@export var storm_line_count := 120
@export var storm_speed := 760.0
@export var storm_line_length := 48.0
@export var storm_line_width := 1.6
@export var storm_rain_color := Color(0.78, 0.88, 1.0, 0.55)
@export_group("Lightning")
@export var lightning_min_interval := 4.0
@export var lightning_max_interval := 9.0
@export var lightning_flash_duration := 0.16
@export var lightning_flash_color := Color(1.0, 1.0, 1.0, 1.0)
@export_group("Audio")
@export var weather_audio_bus := "WeatherSFX"
@export var rain_loop_volume_db := -2.0
@export var thunderstorm_ambience_volume_db := -4.0
@export var indoor_volume_offset_db := -16.0
@export var indoor_lowpass_cutoff_hz := 1150.0
@export var indoor_lowpass_resonance := 0.45

@onready var rain_lines: Node2D = $RainLines
@onready var lightning_flash: ColorRect = $LightningFlash
@onready var rain_audio: AudioStreamPlayer = $RainAudio
@onready var thunderstorm_audio: AudioStreamPlayer = $ThunderstormAudio

var active_weather := GameState.WEATHER_CLEAR
var active_rain_speed := 0.0
var active_rain_direction := Vector2.ZERO
var active_lightning_tween: Tween
var lightning_timer := 0.0
var effects_enabled := false
var weather_lowpass_effect: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = weather_layer
	lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lightning_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	lightning_flash.visible = false
	_configure_weather_audio()

	if not GameState.weather_changed.is_connected(_on_weather_changed):
		GameState.weather_changed.connect(_on_weather_changed)

	if not GameState.state_loaded.is_connected(_on_state_loaded):
		GameState.state_loaded.connect(_on_state_loaded)

	if not GameState.state_changed.is_connected(_on_state_changed):
		GameState.state_changed.connect(_on_state_changed)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	apply_weather(GameState.weather, true)


func _process(delta: float) -> void:
	if not _is_weather_allowed_scene():
		if effects_enabled:
			_disable_weather_visuals()

		_sync_weather_audio()
		return

	if RAIN_WEATHERS.has(active_weather) and not effects_enabled:
		apply_weather(active_weather, true)

	if not RAIN_WEATHERS.has(active_weather):
		return

	_move_rain(delta)

	if active_weather == GameState.WEATHER_THUNDERSTORM:
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			_flash_lightning()
			_reset_lightning_timer()


func apply_weather(weather: String, instant := false) -> void:
	active_weather = weather

	if not RAIN_WEATHERS.has(active_weather):
		_disable_weather_visuals()
		_stop_weather_audio()
		return

	if not _is_weather_allowed_scene():
		_disable_weather_visuals()
		_sync_weather_audio()
		return

	effects_enabled = true
	var line_count: int = rain_line_count
	var line_speed: float = rain_speed
	var line_length: float = rain_line_length
	var line_width: float = rain_line_width
	var line_color: Color = rain_color

	if active_weather == GameState.WEATHER_THUNDERSTORM:
		line_count = storm_line_count
		line_speed = storm_speed
		line_length = storm_line_length
		line_width = storm_line_width
		line_color = storm_rain_color

	active_rain_speed = line_speed
	active_rain_direction = Vector2(cos(deg_to_rad(rain_angle_degrees)), sin(deg_to_rad(rain_angle_degrees))).normalized()
	_rebuild_rain_lines(line_count, line_length, line_width, line_color)
	rain_lines.visible = true

	if active_weather == GameState.WEATHER_THUNDERSTORM:
		_reset_lightning_timer()
	elif not instant:
		lightning_flash.visible = false

	_sync_weather_audio()


func _disable_weather_visuals() -> void:
	effects_enabled = false

	if active_lightning_tween != null:
		active_lightning_tween.kill()
		active_lightning_tween = null

	_clear_rain_lines()
	rain_lines.visible = false
	lightning_flash.visible = false
	lightning_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	lightning_timer = 0.0


func _configure_weather_audio() -> void:
	rain_audio.bus = weather_audio_bus
	thunderstorm_audio.bus = weather_audio_bus
	rain_audio.volume_db = rain_loop_volume_db
	thunderstorm_audio.volume_db = thunderstorm_ambience_volume_db
	_configure_weather_lowpass()

	if not rain_audio.finished.is_connected(_on_rain_audio_finished):
		rain_audio.finished.connect(_on_rain_audio_finished)

	if not thunderstorm_audio.finished.is_connected(_on_thunderstorm_audio_finished):
		thunderstorm_audio.finished.connect(_on_thunderstorm_audio_finished)


func _configure_weather_lowpass() -> void:
	var bus_index: int = AudioServer.get_bus_index(weather_audio_bus)

	if bus_index == -1:
		return

	if AudioServer.get_bus_effect_count(bus_index) == 0:
		weather_lowpass_effect.cutoff_hz = indoor_lowpass_cutoff_hz
		weather_lowpass_effect.resonance = indoor_lowpass_resonance
		AudioServer.add_bus_effect(bus_index, weather_lowpass_effect)
	else:
		var effect: AudioEffect = AudioServer.get_bus_effect(bus_index, 0)
		if effect is AudioEffectLowPassFilter:
			weather_lowpass_effect = effect as AudioEffectLowPassFilter

	AudioServer.set_bus_effect_enabled(bus_index, 0, false)


func _sync_weather_audio() -> void:
	rain_audio.bus = weather_audio_bus
	thunderstorm_audio.bus = weather_audio_bus

	if not _is_weather_audio_allowed_scene() or not RAIN_WEATHERS.has(active_weather):
		_stop_weather_audio()
		return

	var volume_offset: float = 0.0
	var indoor_audio: bool = _is_indoor_weather_audio_scene()
	if indoor_audio:
		volume_offset = indoor_volume_offset_db

	rain_audio.volume_db = rain_loop_volume_db + volume_offset
	thunderstorm_audio.volume_db = thunderstorm_ambience_volume_db + volume_offset
	_set_weather_lowpass_enabled(indoor_audio)

	if not rain_audio.playing:
		rain_audio.play()

	if active_weather == GameState.WEATHER_THUNDERSTORM:
		if not thunderstorm_audio.playing:
			thunderstorm_audio.play()
	else:
		thunderstorm_audio.stop()


func _stop_weather_audio() -> void:
	rain_audio.stop()
	thunderstorm_audio.stop()
	_set_weather_lowpass_enabled(false)


func _is_weather_allowed_scene() -> bool:
	var scene_path: String = _get_active_scene_path()

	if scene_path == "":
		return false

	if outdoor_scene_paths.has(scene_path):
		return true

	for prefix in outdoor_scene_prefixes:
		if scene_path.begins_with(str(prefix)):
			return true

	return false


func _is_weather_audio_allowed_scene() -> bool:
	return _is_weather_allowed_scene() or _is_indoor_weather_audio_scene()


func _is_indoor_weather_audio_scene() -> bool:
	var scene_path: String = _get_active_scene_path()

	if scene_path == "":
		return false

	if indoor_audio_scene_paths.has(scene_path):
		return true

	for prefix in indoor_audio_scene_prefixes:
		if scene_path.begins_with(str(prefix)):
			return true

	return false


func _set_weather_lowpass_enabled(enabled: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(weather_audio_bus)

	if bus_index == -1 or AudioServer.get_bus_effect_count(bus_index) == 0:
		return

	weather_lowpass_effect.cutoff_hz = indoor_lowpass_cutoff_hz
	weather_lowpass_effect.resonance = indoor_lowpass_resonance
	AudioServer.set_bus_effect_enabled(bus_index, 0, enabled)


func _get_active_scene_path() -> String:
	var current_scene: Node = get_tree().current_scene

	if current_scene != null and current_scene.scene_file_path != "":
		return current_scene.scene_file_path

	return GameState.current_scene


func _rebuild_rain_lines(line_count: int, line_length: float, line_width: float, line_color: Color) -> void:
	_clear_rain_lines()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var line_end: Vector2 = active_rain_direction * line_length

	for i in range(max(line_count, 0)):
		var line: Line2D = Line2D.new()
		line.width = line_width
		line.default_color = line_color
		line.points = PackedVector2Array([Vector2.ZERO, line_end])
		line.position = _random_rain_position(viewport_size)
		rain_lines.add_child(line)


func _clear_rain_lines() -> void:
	for child in rain_lines.get_children():
		child.queue_free()


func _move_rain(delta: float) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var velocity: Vector2 = active_rain_direction * active_rain_speed * delta

	for child in rain_lines.get_children():
		if not (child is Line2D):
			continue

		child.position += velocity

		if _is_past_screen(child.position, viewport_size):
			child.position = _random_rain_spawn_position(viewport_size)


func _is_past_screen(position: Vector2, viewport_size: Vector2) -> bool:
	var margin: float = max(rain_line_length, storm_line_length) + 24.0
	return (
		position.y > viewport_size.y + margin
		or position.x < -margin
		or position.x > viewport_size.x + margin
	)


func _random_rain_position(viewport_size: Vector2) -> Vector2:
	return Vector2(
		randf_range(-viewport_size.x * 0.25, viewport_size.x * 1.25),
		randf_range(-viewport_size.y * 0.2, viewport_size.y)
	)


func _random_rain_spawn_position(viewport_size: Vector2) -> Vector2:
	return Vector2(
		randf_range(-viewport_size.x * 0.25, viewport_size.x * 1.25),
		randf_range(-90.0, -10.0)
	)


func _reset_lightning_timer() -> void:
	lightning_timer = randf_range(
		max(lightning_min_interval, 0.1),
		max(lightning_max_interval, lightning_min_interval + 0.1)
	)


func _flash_lightning() -> void:
	if active_lightning_tween != null:
		active_lightning_tween.kill()
		active_lightning_tween = null

	lightning_flash.visible = true
	lightning_flash.color = lightning_flash_color
	var tween: Tween = create_tween()
	active_lightning_tween = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(lightning_flash, "color:a", 0.0, lightning_flash_duration)
	await tween.finished

	if active_lightning_tween != tween:
		return

	lightning_flash.visible = false
	active_lightning_tween = null


func _on_weather_changed(new_weather: String) -> void:
	apply_weather(new_weather)


func _on_state_loaded() -> void:
	apply_weather(GameState.weather, true)


func _on_state_changed() -> void:
	apply_weather(active_weather, true)


func _on_viewport_size_changed() -> void:
	apply_weather(active_weather, true)


func _on_rain_audio_finished() -> void:
	if RAIN_WEATHERS.has(active_weather) and _is_weather_audio_allowed_scene():
		rain_audio.play()


func _on_thunderstorm_audio_finished() -> void:
	if active_weather == GameState.WEATHER_THUNDERSTORM and _is_weather_audio_allowed_scene():
		thunderstorm_audio.play()
