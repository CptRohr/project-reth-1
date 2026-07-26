extends Node

const TIME_BLOCK_GRADIENTS := {
	"morning": {
		"top": Color(0.72, 0.89, 1.0, 1.0),
		"bottom": Color(0.98, 0.97, 0.90, 1.0),
	},
	"after_school": {
		"top": Color(0.98, 0.87, 0.58, 1.0),
		"bottom": Color(0.99, 0.78, 0.48, 1.0),
	},
	"evening": {
		"top": Color(0.74, 0.42, 0.62, 1.0),
		"bottom": Color(0.32, 0.18, 0.38, 1.0),
	},
	"night": {
		"top": Color(0.10, 0.18, 0.36, 1.0),
		"bottom": Color(0.02, 0.05, 0.12, 1.0),
	},
}

const TIME_BLOCK_TINTS := {
	"morning": Color(1.0, 1.0, 1.0, 0.0),
	"after_school": Color(1.0, 0.78, 0.28, 0.06),
	"evening": Color(0.82, 0.34, 0.50, 0.10),
	"night": Color(0.08, 0.16, 0.34, 0.16),
}

const TIME_BLOCK_BRIGHTNESS := {
	"morning": Color(1.0, 1.0, 1.0, 0.0),
	"after_school": Color(0.0, 0.0, 0.0, 0.03),
	"evening": Color(0.0, 0.0, 0.0, 0.08),
	"night": Color(0.0, 0.0, 0.0, 0.14),
}

const WEATHER_OVERLAY_TINTS := {
	"clear": Color(1.0, 1.0, 1.0, 0.0),
	"rain": Color(0.78, 0.84, 0.92, 0.08),
	"thunderstorm": Color(0.60, 0.66, 0.78, 0.14),
}

const GAMEPLAY_SCENE_PREFIX := "res://Areas/"
const NON_GAMEPLAY_SCENE_PREFIXES := [
	"res://Areas/Cutscenes/",
]

const GRADIENT_SHADER := preload("res://Assets/Shaders/time_of_day_gradient.gdshader")

@export var gradient_transition_duration := 0.45
@export var tint_transition_duration := 0.30
@export var brightness_transition_duration := 0.35

@onready var background_layer: CanvasLayer = $BackgroundLayer
@onready var background_rect: ColorRect = $BackgroundLayer/BackgroundRect
@onready var background_material: ShaderMaterial = background_rect.material as ShaderMaterial
@onready var tint_layer: CanvasLayer = $TintLayer
@onready var tint_rect: ColorRect = $TintLayer/TintRect
@onready var brightness_layer: CanvasLayer = $BrightnessLayer
@onready var brightness_rect: ColorRect = $BrightnessLayer/BrightnessRect

var active_tween: Tween
var last_scene_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_layers()

	if not GameState.time_block_changed.is_connected(_on_time_block_changed):
		GameState.time_block_changed.connect(_on_time_block_changed)

	if not GameState.weather_changed.is_connected(_on_weather_changed):
		GameState.weather_changed.connect(_on_weather_changed)

	if not GameState.state_loaded.is_connected(_on_state_loaded):
		GameState.state_loaded.connect(_on_state_loaded)

	if not GameState.state_changed.is_connected(_on_state_changed):
		GameState.state_changed.connect(_on_state_changed)

	last_scene_path = _get_active_scene_path()
	_refresh_scene_layers(true)


func _process(_delta: float) -> void:
	var scene_path := _get_active_scene_path()

	if scene_path == last_scene_path:
		return

	last_scene_path = scene_path
	_refresh_scene_layers(true)


func apply_time_block(time_block: String, instant := false) -> void:
	apply_visuals(time_block, GameState.weather, instant)


func apply_current_gradient(instant := false) -> void:
	apply_visuals(GameState.time_block, GameState.weather, instant)


func apply_visuals(time_block: String, weather: String, instant := false) -> void:
	if not _is_gameplay_scene():
		_set_layer_visibility(false)
		return

	_ensure_material()

	var gradient_data: Dictionary = TIME_BLOCK_GRADIENTS.get(time_block, TIME_BLOCK_GRADIENTS["morning"])
	var base_top: Color = gradient_data.get("top", Color.WHITE)
	var base_bottom: Color = gradient_data.get("bottom", Color.WHITE)
	var base_tint: Color = TIME_BLOCK_TINTS.get(time_block, TIME_BLOCK_TINTS["morning"])
	var base_brightness: Color = TIME_BLOCK_BRIGHTNESS.get(time_block, TIME_BLOCK_BRIGHTNESS["morning"])
	var weather_tint: Color = WEATHER_OVERLAY_TINTS.get(weather, WEATHER_OVERLAY_TINTS["clear"])
	var target_top: Color = _compose_tint(base_top, weather_tint)
	var target_bottom: Color = _compose_tint(base_bottom, weather_tint)
	var target_tint: Color = _compose_tint(base_tint, weather_tint)
	var target_brightness: Color = _compose_tint(base_brightness, weather_tint)

	if active_tween != null:
		active_tween.kill()
		active_tween = null

	_set_layer_visibility(true)

	if instant or (gradient_transition_duration <= 0.0 and tint_transition_duration <= 0.0):
		_set_background_colors(target_top, target_bottom)
		_set_tint_color(target_tint)
		_set_brightness_color(target_brightness)
		return

	var start_top: Color = _get_shader_color("top_color", base_top)
	var start_bottom: Color = _get_shader_color("bottom_color", base_bottom)
	var start_tint: Color = tint_rect.color
	var start_brightness: Color = brightness_rect.color
	var tween: Tween = create_tween()
	active_tween = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_set_background_top_color, start_top, target_top, gradient_transition_duration)
	tween.parallel().tween_method(_set_background_bottom_color, start_bottom, target_bottom, gradient_transition_duration)
	tween.parallel().tween_method(_set_tint_color, start_tint, target_tint, tint_transition_duration)
	tween.parallel().tween_method(_set_brightness_color, start_brightness, target_brightness, brightness_transition_duration)
	await tween.finished

	if active_tween != tween:
		return

	_set_background_colors(target_top, target_bottom)
	_set_tint_color(target_tint)
	_set_brightness_color(target_brightness)
	active_tween = null


func _setup_layers() -> void:
	if background_rect.material == null:
		background_material = ShaderMaterial.new()
		background_material.shader = GRADIENT_SHADER
		background_rect.material = background_material
	else:
		background_material = background_rect.material as ShaderMaterial

	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.color = Color(1, 1, 1, 1)
	background_rect.visible = false
	background_layer.layer = -10

	tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint_rect.visible = false
	tint_rect.color = TIME_BLOCK_TINTS["morning"]
	tint_layer.layer = 1

	brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brightness_rect.visible = false
	brightness_rect.color = TIME_BLOCK_BRIGHTNESS["morning"]
	brightness_layer.layer = 2


func _ensure_material() -> void:
	if background_material == null:
		background_material = ShaderMaterial.new()
		background_material.shader = GRADIENT_SHADER
		background_rect.material = background_material


func _refresh_scene_layers(instant := false) -> void:
	if _is_gameplay_scene():
		_set_layer_visibility(true)
		apply_current_gradient(instant)
	else:
		_set_layer_visibility(false)


func _set_layer_visibility(visible_state: bool) -> void:
	background_rect.visible = visible_state
	tint_rect.visible = visible_state
	brightness_rect.visible = visible_state


func _set_background_colors(top_color: Color, bottom_color: Color) -> void:
	background_material.set_shader_parameter("top_color", top_color)
	background_material.set_shader_parameter("bottom_color", bottom_color)


func _set_background_top_color(top_color: Color) -> void:
	background_material.set_shader_parameter("top_color", top_color)


func _set_background_bottom_color(bottom_color: Color) -> void:
	background_material.set_shader_parameter("bottom_color", bottom_color)


func _set_tint_color(tint_color: Color) -> void:
	tint_rect.color = tint_color
	tint_rect.visible = tint_color.a > 0.001 and _is_gameplay_scene()


func _set_brightness_color(brightness_color: Color) -> void:
	brightness_rect.color = brightness_color
	brightness_rect.visible = brightness_color.a > 0.001 and _is_gameplay_scene()


func _get_shader_color(parameter_name: String, fallback: Color) -> Color:
	if background_material == null:
		return fallback

	var shader_value = background_material.get_shader_parameter(parameter_name)

	if shader_value is Color:
		return shader_value as Color

	return fallback


func _compose_tint(base_color: Color, overlay_color: Color) -> Color:
	var combined_alpha := 1.0 - ((1.0 - base_color.a) * (1.0 - overlay_color.a))

	if combined_alpha <= 0.001:
		return Color(base_color.r, base_color.g, base_color.b, 0.0)

	var base_weight := base_color.a * (1.0 - overlay_color.a)
	var overlay_weight := overlay_color.a

	return Color(
		((base_color.r * base_weight) + (overlay_color.r * overlay_weight)) / combined_alpha,
		((base_color.g * base_weight) + (overlay_color.g * overlay_weight)) / combined_alpha,
		((base_color.b * base_weight) + (overlay_color.b * overlay_weight)) / combined_alpha,
		combined_alpha
	)


func _is_gameplay_scene() -> bool:
	var scene_path := _get_active_scene_path()

	if scene_path == "":
		return false

	if not scene_path.begins_with(GAMEPLAY_SCENE_PREFIX):
		return false

	for prefix in NON_GAMEPLAY_SCENE_PREFIXES:
		if scene_path.begins_with(prefix):
			return false

	return true


func _get_active_scene_path() -> String:
	var current_scene: Node = get_tree().current_scene

	if current_scene != null and current_scene.scene_file_path != "":
		return current_scene.scene_file_path

	return GameState.current_scene


func _on_time_block_changed(new_time_block: String) -> void:
	apply_time_block(new_time_block)


func _on_weather_changed(_new_weather: String) -> void:
	apply_current_gradient()


func _on_state_loaded() -> void:
	last_scene_path = _get_active_scene_path()
	_refresh_scene_layers(true)


func _on_state_changed() -> void:
	last_scene_path = _get_active_scene_path()
	_refresh_scene_layers(true)
