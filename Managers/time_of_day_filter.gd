extends CanvasLayer

const TIME_BLOCK_TINTS := {
	"morning": Color(1.0, 1.0, 1.0, 0.0),
	"after_school": Color(1.0, 0.75, 0.22, 0.12),
	"evening": Color(0.85, 0.38, 0.55, 0.16),
	"night": Color(0.08, 0.16, 0.38, 0.28),
}

@export var tint_transition_duration := 0.45

@onready var tint_rect: ColorRect = $TintRect

var active_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1
	tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not GameState.time_block_changed.is_connected(_on_time_block_changed):
		GameState.time_block_changed.connect(_on_time_block_changed)

	if not GameState.state_loaded.is_connected(_on_state_loaded):
		GameState.state_loaded.connect(_on_state_loaded)

	apply_time_block(GameState.time_block, true)


func apply_time_block(time_block: String, instant := false) -> void:
	var target_color: Color = TIME_BLOCK_TINTS.get(time_block, Color(0.0, 0.0, 0.0, 0.0))

	if active_tween != null:
		active_tween.kill()
		active_tween = null

	if instant or tint_transition_duration <= 0.0:
		_set_tint_color(target_color)
		return

	tint_rect.visible = true
	var tint_tween := create_tween()
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


func _on_time_block_changed(new_time_block: String) -> void:
	apply_time_block(new_time_block)


func _on_state_loaded() -> void:
	apply_time_block(GameState.time_block, true)
