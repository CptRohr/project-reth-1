extends Node2D

@export_file("*.json") var timeline_path: String = ""
@export var auto_play: bool = true
@export var skip_input_actions: PackedStringArray = ["dialogic_default_action", "interact", "pause_menu"]
@export var caption_label_path: NodePath = ^"Overlay/Root/CaptionLabel"
@export var phone_panel_path: NodePath = ^"Overlay/Root/PhonePanel"
@export var phone_label_path: NodePath = ^"Overlay/Root/PhonePanel/MarginContainer/PhoneLabel"
@export var black_screen_path: NodePath = ^"Overlay/Root/BlackScreen"
@export var skip_hint_path: NodePath = ^"Overlay/Root/SkipHint"

var allow_skip: bool = false
var ending: bool = false
var timeline_steps: Array = []
var skip_steps: Array = []
var active_tweens: Array[Tween] = []

var caption_label: Label
var phone_panel: Control
var phone_label: Label
var black_screen: ColorRect
var skip_hint: CanvasItem


func _ready() -> void:
	GameState.set_scene(scene_file_path)
	_cache_common_nodes()
	_load_timeline()
	_on_director_ready()

	if auto_play:
		play_timeline()


func _unhandled_input(event: InputEvent) -> void:
	if not allow_skip or ending or not event.is_pressed():
		return

	for action_name in skip_input_actions:
		if event.is_action_pressed(action_name):
			get_viewport().set_input_as_handled()
			_skip_cutscene()
			return


func play_timeline() -> void:
	for step in timeline_steps:
		if ending:
			return

		await _run_step(step)


func _skip_cutscene() -> void:
	if ending:
		return

	ending = true
	allow_skip = false
	_kill_active_tweens()
	_set_skip_hint(false)
	await _run_skip_steps()


func _run_skip_steps() -> void:
	for step in skip_steps:
		await _run_step(step, true)


func _run_step(raw_step: Variant, force_run: bool = false) -> void:
	if ending and not force_run:
		return

	if not raw_step is Dictionary:
		push_warning("Cutscene step must be a Dictionary.")
		return

	var step: Dictionary = raw_step
	var action := str(step.get("action", ""))

	match action:
		"wait":
			await _step_wait(step)
		"caption":
			_step_caption(step)
		"phone":
			_step_phone(step)
		"black":
			_step_black(step)
		"fade_black":
			await _step_fade_black(step)
		"location":
			_step_location(step)
		"visible":
			_step_visible(step)
		"position":
			_step_position(step)
		"move":
			_step_move(step)
		"pulse_caption":
			await _step_pulse_caption(step)
		"allow_skip":
			_step_allow_skip(step)
		"set_flag":
			_step_set_flag(step)
		"change_scene":
			await _step_change_scene(step)
		"call":
			await _step_call(step)
		_:
			push_warning("Unknown cutscene action: %s" % action)


func _cache_common_nodes() -> void:
	caption_label = get_node_or_null(caption_label_path) as Label
	phone_panel = get_node_or_null(phone_panel_path) as Control
	phone_label = get_node_or_null(phone_label_path) as Label
	black_screen = get_node_or_null(black_screen_path) as ColorRect
	skip_hint = get_node_or_null(skip_hint_path) as CanvasItem


func _load_timeline() -> void:
	if timeline_path == "":
		push_warning("CutsceneDirector has no timeline_path.")
		return

	if not FileAccess.file_exists(timeline_path):
		push_error("Cutscene timeline not found: %s" % timeline_path)
		return

	var file := FileAccess.open(timeline_path, FileAccess.READ)
	if file == null:
		push_error("Could not read cutscene timeline: %s" % timeline_path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Cutscene timeline must be a JSON object: %s" % timeline_path)
		return

	var data: Dictionary = parsed
	var raw_steps: Variant = data.get("steps", [])
	if raw_steps is Array:
		timeline_steps = raw_steps

	var raw_skip_steps: Variant = data.get("skip_steps", [])
	if raw_skip_steps is Array:
		skip_steps = raw_skip_steps


func _step_wait(step: Dictionary) -> void:
	var duration: float = float(step.get("duration", 0.0))
	await get_tree().create_timer(duration).timeout


func _step_caption(step: Dictionary) -> void:
	if caption_label == null:
		return

	var text := str(step.get("text", ""))
	caption_label.text = text
	caption_label.visible = bool(step.get("visible", text != ""))


func _step_phone(step: Dictionary) -> void:
	if phone_panel != null:
		phone_panel.visible = bool(step.get("visible", true))

	if phone_label != null and step.has("text"):
		phone_label.text = str(step["text"])


func _step_black(step: Dictionary) -> void:
	if black_screen == null:
		return

	var alpha: float = float(step.get("alpha", 1.0))
	black_screen.visible = bool(step.get("visible", alpha > 0.0))
	black_screen.color = Color(0, 0, 0, alpha)


func _step_fade_black(step: Dictionary) -> void:
	if black_screen == null:
		return

	var from_alpha: float = float(step.get("from", black_screen.color.a))
	var to_alpha: float = float(step.get("to", 0.0))
	var duration: float = float(step.get("duration", 0.0))
	black_screen.visible = true
	black_screen.color = Color(0, 0, 0, from_alpha)

	var tween := create_tween()
	active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))
	tween.tween_property(black_screen, "color:a", to_alpha, duration)
	await tween.finished
	black_screen.visible = bool(step.get("stay_visible", to_alpha > 0.0))


func _step_location(step: Dictionary) -> void:
	var location_name := str(step.get("name", ""))
	show_location(location_name)


func _step_visible(step: Dictionary) -> void:
	var node := _get_target_node(step)
	if node == null:
		return

	if node is CanvasItem:
		(node as CanvasItem).visible = bool(step.get("value", true))


func _step_position(step: Dictionary) -> void:
	var node := _get_target_node(step) as Node2D
	if node == null:
		return

	node.position = _read_vector2(step.get("position", [0, 0]))


func _step_move(step: Dictionary) -> void:
	var node := _get_target_node(step) as Node2D
	if node == null:
		return

	var from_position: Vector2 = _read_vector2(step.get("from", [node.position.x, node.position.y]))
	var to_position: Vector2 = _read_vector2(step.get("to", [node.position.x, node.position.y]))
	var duration: float = float(step.get("duration", 0.0))
	node.position = from_position

	var tween := create_tween()
	active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))
	tween.tween_property(node, "position", to_position, duration)


func _step_pulse_caption(step: Dictionary) -> void:
	if caption_label == null:
		return

	var count: int = int(step.get("count", 1))
	var delay: float = float(step.get("delay", 0.25))

	for _i in range(count):
		if ending:
			return

		caption_label.visible = true
		await get_tree().create_timer(delay).timeout
		if ending:
			return

		caption_label.visible = false
		await get_tree().create_timer(delay).timeout

	caption_label.visible = true


func _step_allow_skip(step: Dictionary) -> void:
	allow_skip = bool(step.get("value", true))
	_set_skip_hint(allow_skip and bool(step.get("show_hint", true)))


func _step_set_flag(step: Dictionary) -> void:
	var flag_name := str(step.get("name", ""))
	if flag_name == "":
		return

	GameState.set_flag(flag_name, step.get("value", true))


func _step_change_scene(step: Dictionary) -> void:
	var scene_path := str(step.get("scene", ""))
	var spawn_id := str(step.get("spawn", ""))
	if scene_path == "":
		return

	await SceneManager.transition_to(scene_path, spawn_id)


func _step_call(step: Dictionary) -> void:
	var method_name := str(step.get("method", ""))
	if method_name == "" or not has_method(method_name):
		push_warning("Cutscene call method not found: %s" % method_name)
		return

	var args: Array = []
	var raw_args: Variant = step.get("args", [])
	if raw_args is Array:
		args = raw_args

	var result: Variant = callv(method_name, args)
	if result is Signal:
		await result


func _get_target_node(step: Dictionary) -> Node:
	var target_path := str(step.get("target", ""))
	if target_path == "":
		return null

	var node := get_node_or_null(NodePath(target_path))
	if node == null:
		push_warning("Cutscene target not found: %s" % target_path)

	return node


func _read_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value

	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))

	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))

	return Vector2.ZERO


func _kill_active_tweens() -> void:
	for tween in active_tweens:
		if tween != null:
			tween.kill()

	active_tweens.clear()


func _on_tween_finished(tween: Tween) -> void:
	active_tweens.erase(tween)


func _set_skip_hint(should_show: bool) -> void:
	if skip_hint != null:
		skip_hint.visible = should_show


func show_location(_location_name: String) -> void:
	pass


func _on_director_ready() -> void:
	pass
