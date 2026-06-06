extends CanvasLayer

const TIME_BLOCK_TINTS := {
	"morning": Color(1.0, 1.0, 1.0, 0.0),
	"after_school": Color(1.0, 0.75, 0.22, 0.12),
	"evening": Color(0.85, 0.38, 0.55, 0.16),
	"night": Color(0.08, 0.16, 0.38, 0.28),
}

@export var tint_transition_duration := 0.45
@export var weather_tint_scene_paths: PackedStringArray = [
	"res://Areas/street.tscn",
	"res://Areas/street2.tscn",
	"res://Areas/street3.tscn",
]
@export var weather_tint_scene_prefixes: PackedStringArray = []

@onready var tint_rect: ColorRect = $TintRect

var active_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1
	tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not GameState.time_block_changed.is_connected(_on_time_block_changed):
		GameState.time_block_changed.connect(_on_time_block_changed)

	if not GameState.weather_changed.is_connected(_on_weather_changed):
		GameState.weather_changed.connect(_on_weather_changed)

	if not GameState.state_loaded.is_connected(_on_state_loaded):
		GameState.state_loaded.connect(_on_state_loaded)

	if not GameState.state_changed.is_connected(_on_state_changed):
		GameState.state_changed.connect(_on_state_changed)

	apply_current_tint(true)


func apply_time_block(time_block: String, instant := false) -> void:
	apply_tint(time_block, GameState.weather, instant)


func apply_current_tint(instant := false) -> void:
	apply_tint(GameState.time_block, GameState.weather, instant)


func apply_tint(time_block: String, weather: String, instant := false) -> void:
	var time_color: Color = TIME_BLOCK_TINTS.get(time_block, Color(0.0, 0.0, 0.0, 0.0))
	var weather_color: Color = _get_scene_weather_tint(weather)
	var target_color: Color = _compose_tints(time_color, weather_color)

	if active_tween != null:
		active_tween.kill()
		active_tween = null

	if instant or tint_transition_duration <= 0.0:
		_set_tint_color(target_color)
		return

	tint_rect.visible = true
	var tint_tween: Tween = create_tween()
	active_tween = tint_tween
	tint_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tint_tween.tween_method(_set_tint_color, tint_rect.color, target_color, tint_transition_duration)
	await tint_tween.finished

	if active_tween != tint_tween:
		return

	_set_tint_color(target_color)
	active_tween = null


func _set_tint_color(color: Color) -> void:
	tint_rect.color = color
	tint_rect.visible = color.a > 0.001


func _compose_tints(base_color: Color, overlay_color: Color) -> Color:
	var combined_alpha := 1.0 - ((1.0 - base_color.a) * (1.0 - overlay_color.a))

	if combined_alpha <= 0.001:
		return Color(1.0, 1.0, 1.0, 0.0)

	var base_weight := base_color.a * (1.0 - overlay_color.a)
	var overlay_weight := overlay_color.a

	return Color(
		((base_color.r * base_weight) + (overlay_color.r * overlay_weight)) / combined_alpha,
		((base_color.g * base_weight) + (overlay_color.g * overlay_weight)) / combined_alpha,
		((base_color.b * base_weight) + (overlay_color.b * overlay_weight)) / combined_alpha,
		combined_alpha
	)


func _get_scene_weather_tint(weather: String) -> Color:
	if not _is_weather_tint_allowed_scene():
		return Color(1.0, 1.0, 1.0, 0.0)

	return GameState.get_weather_tint(weather)


func _is_weather_tint_allowed_scene() -> bool:
	var scene_path: String = _get_active_scene_path()

	if scene_path == "":
		return false

	if weather_tint_scene_paths.has(scene_path):
		return true

	for prefix in weather_tint_scene_prefixes:
		if scene_path.begins_with(str(prefix)):
			return true

	return false


func _get_active_scene_path() -> String:
	var current_scene: Node = get_tree().current_scene

	if current_scene != null and current_scene.scene_file_path != "":
		return current_scene.scene_file_path

	return GameState.current_scene


func _on_time_block_changed(new_time_block: String) -> void:
	apply_time_block(new_time_block)


func _on_weather_changed(_new_weather: String) -> void:
	apply_current_tint()


func _on_state_loaded() -> void:
	apply_current_tint(true)


func _on_state_changed() -> void:
	apply_current_tint(true)
