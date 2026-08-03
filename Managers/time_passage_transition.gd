extends CanvasLayer

@export var fade_duration := 0.9
@export var text_hold_duration := 1.15
@export_multiline var activity_text_template := "{activity} passed\n{time}"
@export_multiline var empty_activity_text_template := "Time passed\n{time}"
@export_multiline var new_day_text_template := "A new day begins\n{time}"
@export var use_shader_transitions := true
@export var out_transition_shader: Shader = preload("res://Assets/Shaders/square_transition.gdshader")
@export var in_transition_shader: Shader = preload("res://Assets/Shaders/slash_transition.gdshader")
@export var transition_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var fallback_overlay_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var square_translate: Vector2 = Vector2(-0.25, -0.25)
@export var square_extra_size: float = 1.0
@export var slash_normal: Vector2 = Vector2(1.0, 1.0)
@export var slash_offset: float = -0.5
@export var slash_power: float = 10.0
@export var text_fade_duration: float = 0.25
@export var text_visible_alpha: float = 1.0
@export var text_hidden_alpha: float = 0.0
@export var text_fade_during_in := true
@export var text_fade_during_out := true
@export var text_jitter_strength: float = 2.0
@export var text_jitter_speed: float = 8.0
@export var text_jitter_frequency: float = 12.0
@export var text_separate_xy := true
@export var text_time_offset: float = 0.0
@export var text_enable_rotation := true
@export var text_rotation_strength: float = 5.0
@export var text_rotation_speed: float = 3.0
@export var text_rotation_frequency: float = 4.0
@export var text_enable_scaling := true
@export var text_scale_strength: float = 0.1
@export var text_scale_speed: float = 2.5
@export var text_scale_frequency: float = 6.0
@export var text_base_scale: float = 1.0
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var text_use_custom_color := false
@export var text_shake_intensity: float = 0.0
@export var text_enable_pixelation := true
@export var text_pixel_size: float = 1.0
@export var text_adaptive_pixels := true
@export var text_enable_outline := true
@export var text_outline_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var text_outline_thickness: float = 1.0
@export var text_chromatic_aberration := false
@export var text_aberration_strength: float = 1.0

@onready var overlay: ColorRect = $Overlay
@onready var passage_label: Label = $Overlay/CenterContainer/PassageLabel

var active := false
var active_tween: Tween
var text_tween: Tween
var out_shader_material: ShaderMaterial
var in_shader_material: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	if overlay == null or passage_label == null:
		push_error("TimePassageTransition is missing required nodes. Check Scene/TimePassageTransition.tscn.")
		set_process(false)
		return
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.color = fallback_overlay_color
	passage_label.modulate = Color(passage_label.modulate.r, passage_label.modulate.g, passage_label.modulate.b, 0.0)
	_configure_text_material()
	_configure_materials()
	visible = false


func play(action_label: String, state_change: Callable) -> bool:
	if active:
		return false

	active = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	visible = true
	passage_label.text = ""
	_set_text_alpha(text_hidden_alpha)

	await _transition_in()

	if state_change.is_valid():
		state_change.call()

	passage_label.text = _build_passage_text(action_label)
	await _animate_text_alpha(text_hidden_alpha, text_visible_alpha, text_fade_during_in)
	await get_tree().create_timer(text_hold_duration, true).timeout
	await _animate_text_alpha(text_visible_alpha, text_hidden_alpha, text_fade_during_out)
	await _transition_out()

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


func _transition_out() -> void:
	if use_shader_transitions and out_shader_material != null:
		await _play_shader_transition(out_shader_material, 1.0, 0.0, false)
		return

	await _fade(0.0, 1.0)


func _transition_in() -> void:
	if use_shader_transitions and in_shader_material != null:
		await _play_shader_transition(in_shader_material, 0.0, 1.0, true)
		return

	await _fade(1.0, 0.0)


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


func _play_shader_transition(material: ShaderMaterial, from_t: float, to_t: float, stay_visible: bool) -> void:
	if active_tween != null:
		active_tween.kill()

	overlay.material = material
	overlay.color = transition_color
	overlay.visible = true
	_configure_shader_runtime(material)
	_set_shader_t(from_t, material)

	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_method(Callable(self, "_set_shader_t").bind(material), from_t, to_t, fade_duration)
	await active_tween.finished

	_set_shader_t(to_t, material)
	overlay.visible = stay_visible
	active_tween = null


func _set_shader_t(value: float, material: ShaderMaterial) -> void:
	if material == null:
		return

	material.set_shader_parameter("t", clampf(value, 0.0, 1.0))


func _animate_text_alpha(from_alpha: float, to_alpha: float, enabled: bool) -> void:
	if not enabled or text_fade_duration <= 0.0:
		_set_text_alpha(to_alpha)
		return

	if text_tween != null:
		text_tween.kill()

	_set_text_alpha(from_alpha)
	text_tween = create_tween()
	text_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	text_tween.tween_method(_set_text_alpha, from_alpha, to_alpha, text_fade_duration)
	await text_tween.finished

	_set_text_alpha(to_alpha)
	text_tween = null


func _configure_materials() -> void:
	if use_shader_transitions:
		out_shader_material = _build_shader_material(out_transition_shader)
		in_shader_material = _build_shader_material(in_transition_shader)
	else:
		out_shader_material = null
		in_shader_material = null

	overlay.material = out_shader_material if out_shader_material != null else null
	_configure_shader_runtime(out_shader_material)
	_configure_shader_runtime(in_shader_material)


func _build_shader_material(shader: Shader) -> ShaderMaterial:
	if shader == null:
		return null

	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _configure_shader_runtime(material: ShaderMaterial) -> void:
	if material == null:
		return

	var shader_path := ""
	if material.shader != null:
		shader_path = material.shader.resource_path.to_lower()

	material.set_shader_parameter("mask_color", transition_color)
	material.set_shader_parameter("background_color", fallback_overlay_color)
	material.set_shader_parameter("t", 0.0)

	if shader_path.ends_with("square_transition.gdshader"):
		material.set_shader_parameter("translate", square_translate)
		material.set_shader_parameter("extra_size", square_extra_size)

	if shader_path.ends_with("slash_transition.gdshader"):
		material.set_shader_parameter("normal", slash_normal)
		material.set_shader_parameter("offset", slash_offset)
		material.set_shader_parameter("power", slash_power)


func _set_alpha(value: float) -> void:
	overlay.color = Color(
		fallback_overlay_color.r,
		fallback_overlay_color.g,
		fallback_overlay_color.b,
		value
	)


func _set_text_alpha(value: float) -> void:
	var modulate := passage_label.modulate
	modulate.a = clampf(value, 0.0, 1.0)
	passage_label.modulate = modulate


func _configure_text_material() -> void:
	var material := passage_label.material as ShaderMaterial
	if material == null:
		return

	material.set_shader_parameter("jitter_strength", text_jitter_strength)
	material.set_shader_parameter("jitter_speed", text_jitter_speed)
	material.set_shader_parameter("jitter_frequency", text_jitter_frequency)
	material.set_shader_parameter("separate_xy", text_separate_xy)
	material.set_shader_parameter("time_offset", text_time_offset)
	material.set_shader_parameter("enable_rotation", text_enable_rotation)
	material.set_shader_parameter("rotation_strength", text_rotation_strength)
	material.set_shader_parameter("rotation_speed", text_rotation_speed)
	material.set_shader_parameter("rotation_frequency", text_rotation_frequency)
	material.set_shader_parameter("enable_scaling", text_enable_scaling)
	material.set_shader_parameter("scale_strength", text_scale_strength)
	material.set_shader_parameter("scale_speed", text_scale_speed)
	material.set_shader_parameter("scale_frequency", text_scale_frequency)
	material.set_shader_parameter("base_scale", text_base_scale)
	material.set_shader_parameter("text_color", text_color)
	material.set_shader_parameter("use_custom_color", text_use_custom_color)
	material.set_shader_parameter("shake_intensity", text_shake_intensity)
	material.set_shader_parameter("enable_pixelation", text_enable_pixelation)
	material.set_shader_parameter("pixel_size", text_pixel_size)
	material.set_shader_parameter("adaptive_pixels", text_adaptive_pixels)
	material.set_shader_parameter("enable_outline", text_enable_outline)
	material.set_shader_parameter("outline_color", text_outline_color)
	material.set_shader_parameter("outline_thickness", text_outline_thickness)
	material.set_shader_parameter("chromatic_aberration", text_chromatic_aberration)
	material.set_shader_parameter("aberration_strength", text_aberration_strength)
