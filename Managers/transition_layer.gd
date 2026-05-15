extends CanvasLayer

@export var transition_duration: float = 0.6
@export var hidden_radius: float = 0.0
@export var covered_radius: float = 1.25
@export var pixel_size: float = 8.0
@export var falloff: float = 2.5
@export var dither_offset: Vector2 = Vector2(2.0, 0.0)
@export var transition_color: Color = Color.BLACK
@export var use_dither_on_mobile: bool = false

@onready var transition_rect: ColorRect = $ColorRect

var shader_material: ShaderMaterial
var active_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	shader_material = transition_rect.material as ShaderMaterial
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.visible = false
	transition_rect.color = Color(transition_color.r, transition_color.g, transition_color.b, 0.0)
	_update_shader_settings()
	_set_radius(hidden_radius)


func fade_out() -> void:
	if _should_use_plain_fade():
		await _play_plain_fade(0.0, transition_color.a, true)
		return

	await _play_dither_transition(hidden_radius, covered_radius, true)


func fade_in() -> void:
	if _should_use_plain_fade():
		await _play_plain_fade(transition_color.a, 0.0, false)
		return

	await _play_dither_transition(covered_radius, hidden_radius, false)


func _play_dither_transition(from_radius: float, to_radius: float, stay_visible: bool = false) -> void:
	if shader_material == null:
		if to_radius > from_radius:
			await _play_plain_fade(0.0, transition_color.a, stay_visible)
		else:
			await _play_plain_fade(transition_color.a, 0.0, stay_visible)
		return

	if active_tween != null:
		active_tween.kill()

	transition_rect.material = shader_material
	_update_shader_settings()
	transition_rect.visible = true
	_set_radius(from_radius)

	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_method(_set_radius, from_radius, to_radius, transition_duration)
	await active_tween.finished

	_set_radius(to_radius)
	transition_rect.visible = stay_visible
	active_tween = null


func _play_plain_fade(from_alpha: float, to_alpha: float, stay_visible: bool = false) -> void:
	if active_tween != null:
		active_tween.kill()

	transition_rect.material = null
	transition_rect.visible = true
	_set_plain_alpha(from_alpha)

	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_method(_set_plain_alpha, from_alpha, to_alpha, transition_duration)
	await active_tween.finished

	_set_plain_alpha(to_alpha)
	transition_rect.visible = stay_visible
	active_tween = null


func _set_radius(value: float) -> void:
	if shader_material == null:
		return

	shader_material.set_shader_parameter("radius", value)


func _set_plain_alpha(value: float) -> void:
	transition_rect.color = Color(
		transition_color.r,
		transition_color.g,
		transition_color.b,
		value
	)


func _should_use_plain_fade() -> bool:
	return OS.has_feature("mobile") and not use_dither_on_mobile


func _update_shader_settings() -> void:
	if shader_material == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	shader_material.set_shader_parameter("resolution", viewport_size)
	shader_material.set_shader_parameter("pixel_size", pixel_size)
	shader_material.set_shader_parameter("falloff", falloff)
	shader_material.set_shader_parameter("dither_offset", dither_offset)
	shader_material.set_shader_parameter("color", transition_color)
	shader_material.set_shader_parameter("invert", false)
