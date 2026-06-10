@tool
class_name VHSColorWheel extends ColorRect

const SHADER_VHS_WHEEL := preload("res://addons/extended_ui/controls/color/XUI_VHS_Wheel.gdshader")

enum TYPE { VHS_CIRCLE }
var type := TYPE.VHS_CIRCLE

var shader_material := ShaderMaterial.new()

@export var value : float = 1.0:
	set(v):
		if value != v:
			value = v
			color = Color.from_hsv(color.h, color.s, value)
			_update_cursor_position()
			
			if shader_material:
				shader_material.set_shader_parameter("value", value)
			
			queue_redraw()

@export var show_dot := true

signal color_selected(color: Color)


func _set(property: StringName, val: Variant) -> bool:
	if property == "color":
		if color != val:
			color = val
			value = color.v
			if shader_material:
				shader_material.set_shader_parameter("value", value)
				_update_cursor_position()
			
	return false


func _get_minimum_size() -> Vector2:
	return Vector2(64, 64)

var wheel_center: Vector2:
	get: return size * 0.5

var wheel_radius: float:
	get: return min(size.x, size.y) * 0.5


func _ready() -> void:
	shader_material.shader = SHADER_VHS_WHEEL
	material = shader_material
	_update_shader_params()
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_shader_params()
		queue_redraw()


func _update_shader_params():
	# These names must match your shader uniforms.
	# For the shader version I suggested:
	#   center_uv (vec2), radius_uv (float), aspect (float), value (float)
	shader_material.set_shader_parameter("center_uv", wheel_center / size)
	# radius is expressed in UV relative to height when using aspect scaling
	var radius_uv = wheel_radius / max(1.0, size.y)
	shader_material.set_shader_parameter("radius_uv", radius_uv)
	shader_material.set_shader_parameter("aspect", size.x / max(1.0, size.y))
	shader_material.set_shader_parameter("value", value)
	shader_material.set_shader_parameter("show_cursor", show_dot)
	_update_cursor_position()


func vhs_to_color(angle_deg: float, radius_px: float) -> Color:
	var hue := fmod(angle_deg, 360.0)
	if hue < 0.0: hue += 360.0
	var sat = clamp(radius_px / wheel_radius, 0.0, 1.0)
	return Color.from_hsv(hue / 360.0, sat, value)


func _update_cursor_position() -> void:
	if not shader_material:
		return
	
	# Calculate cursor position in UV coordinates based on current color
	var hue_deg := color.h * 360.0
	var sat := color.s
	var angle_rad := deg_to_rad(hue_deg)
	var radius := sat * wheel_radius
	
	var cursor_pos := wheel_center + Vector2(cos(angle_rad), sin(angle_rad)) * radius
	var cursor_uv := cursor_pos / size
	shader_material.set_shader_parameter("cursor_uv", cursor_uv)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_pick_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_pick_at(event.position)
		accept_event()


func _pick_at(pos: Vector2) -> void:
	# Vector from center to mouse in pixels
	var d := pos - wheel_center

	# Optional: if your shader applies aspect correction (d.x *= aspect),
	# do the SAME here so the math matches. Uncomment if needed.
	# d.x *= size.x / max(1.0, size.y)

	var r := d.length()
	if r > wheel_radius:
		# Clamp to the circle edge (or return if you want "no pick" outside)
		d = d.normalized() * wheel_radius
		r = wheel_radius

	var angle_rad := atan2(d.y, d.x)             # [-PI, PI]
	var angle_deg := rad_to_deg(angle_rad)        # [-180, 180]
	if angle_deg < 0.0: angle_deg += 360.0        # [0, 360)

	color = vhs_to_color(angle_deg, r)
	_update_cursor_position()
	emit_signal("color_selected", color)
