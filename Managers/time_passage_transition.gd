extends CanvasLayer

@export var fade_duration := 0.35
@export var text_hold_duration := 1.15
@export_multiline var activity_text_template := "{activity} passed\n{time}"
@export_multiline var empty_activity_text_template := "Time passed\n{time}"
@export_multiline var new_day_text_template := "A new day begins\n{time}"

@onready var overlay: ColorRect = $Overlay
@onready var passage_label: Label = $CenterContainer/PassageLabel

var active := false
var active_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.color = Color(overlay.color.r, overlay.color.g, overlay.color.b, 0.0)
	passage_label.modulate = Color(passage_label.modulate.r, passage_label.modulate.g, passage_label.modulate.b, 0.0)
	visible = false


func play(action_label: String, state_change: Callable) -> bool:
	if active:
		return false

	active = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	visible = true
	passage_label.text = ""
	passage_label.modulate.a = 0.0

	await _fade(0.0, 1.0)

	if state_change.is_valid():
		state_change.call()

	passage_label.text = _build_passage_text(action_label)
	passage_label.modulate.a = 1.0

	await get_tree().create_timer(text_hold_duration, true).timeout
	await _fade(1.0, 0.0)

	visible = false
	get_tree().paused = was_paused
	active = false
	return true


func _build_passage_text(action_label: String) -> String:
	var trimmed_label := action_label.strip_edges()
	var destination := GameState.get_time_block_label()
	var template := activity_text_template

	if trimmed_label == "":
		template = empty_activity_text_template
	elif trimmed_label.to_lower() == "a new day begins":
		template = new_day_text_template

	return template.replace("{activity}", trimmed_label).replace("{time}", destination)


func _fade(from_alpha: float, to_alpha: float) -> void:
	if active_tween != null:
		active_tween.kill()

	_set_alpha(from_alpha)
	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_method(_set_alpha, from_alpha, to_alpha, fade_duration)
	await active_tween.finished

	_set_alpha(to_alpha)
	active_tween = null


func _set_alpha(value: float) -> void:
	overlay.color.a = value
	passage_label.modulate.a = min(passage_label.modulate.a, value)
