## Extended UI: HSlider
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io

## A 2D Slider representing a point in 2D space.
## Commonly used in musical applications to control multiple values in 1 control.
@tool class_name XUI2DSlider extends Control

@export var editable := true
@export var x_editable := true
@export var y_editable := true

@export var value := Vector2(0.5, 0.5)
@export var default_value := Vector2(0.5, 0.5)
@export var min_value := Vector2.ZERO
@export var max_value := Vector2.ONE

signal value_changed(xy : Vector2)
signal x_value_changed(x : float)
signal y_value_changed(y : float)
signal mouse_entered_handle()
signal mouse_exited_handle()

var _handle_hovered := false
var _is_dragging := false
var _drag_start_value := Vector2()
var _drag_start_mouse := Vector2()

var _default_handle_size := 8
var _default_handle_size_hover := 10
var _default_handle_color := Color(1.0, 1.0, 1.0, 0.5)
var _default_handle_color_hover := Color(1.0, 1.0, 1.0, 1.0)
var _default_grid_color := Color.DIM_GRAY
var _default_grid_line_thickness := 1
var _default_handle_line_color := Color.GRAY

func _get_minimum_size() -> Vector2:
	return Vector2(32, 32)


func _gui_input(event: InputEvent) -> void:
	var handle_rect := _get_handle_rect()
	
	if event is InputEventMouseMotion:
		var mouse = event.position
		
		if _is_dragging:
			_update_dragging()
		elif not _handle_hovered and handle_rect.has_point(mouse):
			_handle_hovered = true
			mouse_entered_handle.emit()
			queue_redraw()
		elif _handle_hovered and not handle_rect.has_point(mouse):
			_handle_hovered = false
			mouse_exited_handle.emit()
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _handle_hovered and event.pressed and not _is_dragging:
				_start_dragging()
			elif event.is_released() and _is_dragging:
				_stop_dragging()


func _start_dragging() -> void:
	var mouse = get_local_mouse_position()
	_drag_start_mouse = mouse
	_drag_start_value = value
	_is_dragging = true

func _update_dragging() -> void:
	var mouse = get_local_mouse_position()
	
	var mouse_delta = mouse - _drag_start_mouse
	
	var old_handle_pos = _value_to_handle_position(_drag_start_value)
	old_handle_pos += mouse_delta
	
	# clamp handle
	old_handle_pos = _clamp_handle_pos(old_handle_pos)
	
	var new_value = _handle_pos_to_value(old_handle_pos)
	value = new_value
	value_changed.emit(value)
	queue_redraw()


func _stop_dragging() -> void:
	_is_dragging = false


func _draw() -> void:
	# draw background
	_draw_bg()
	
	# draw center grid lines
	_draw_grid()
	
	# draw the handle axis and handle
	_draw_handle()


func _draw_bg() -> void:
	var bg_style : StyleBox
	if has_theme_stylebox("slider"):
		bg_style = get_theme_stylebox("slider")
	else:
		bg_style = get_theme_stylebox("slider", "HSlider")
	
	draw_style_box(bg_style, Rect2(0, 0, size.x, size.y))


func _draw_grid() -> void:
	var grid_line_color := _default_grid_color
	var grid_line_thickness := _default_grid_line_thickness
	
	if has_theme_color("grid_color"):
		grid_line_color = get_theme_color("grid_color")
	if has_theme_constant("grid_line_thickness"):
		grid_line_thickness = get_theme_constant("grid_line_thickness")
	
	var center = size / 2
	
	# horizontal line
	draw_line(Vector2(0, center.y), Vector2(size.x, center.y), grid_line_color, grid_line_thickness, true)
	
	# vertical line
	draw_line(Vector2(center.x, 0), Vector2(center.x, size.y), grid_line_color, grid_line_thickness, true)


func _draw_handle() -> void:
	var handle_color := _default_handle_color
	if _handle_hovered or _is_dragging:
		handle_color = _default_handle_color_hover
	
	var handle_size := _default_handle_size
	if _handle_hovered or _is_dragging:
		handle_size = _default_handle_size_hover
	
	if has_theme_color("handle_color"):
		handle_color = get_theme_color("handle_color")
	
	var handle_radius = handle_size / 2
	var handle_pos := _get_handle_position()
	draw_circle(handle_pos, handle_radius, handle_color, true, -1.0, true)


## Remap a handle position to a slider value
## It's not 1-1 due to margins (better UX)
func _handle_pos_to_value(handle_pos : Vector2) -> Vector2:
	var margins = _default_handle_size_hover / 2
	var x = remap(handle_pos.x, margins, size.x - margins, min_value.x, max_value.x)
	var y = remap(handle_pos.y, margins, size.y - margins, min_value.y, max_value.y)
	
	return Vector2(x, y)

## Remap a slider value to a handle position
## It's not 1-1 due to margins (better UX)
func _value_to_handle_position(val : Vector2) -> Vector2:
	var margins = _default_handle_size_hover / 2
	var x = remap(val.x, min_value.x, max_value.x, margins, size.x - margins)
	var y = remap(val.y, min_value.y, max_value.y, margins, size.y - margins)

	return Vector2(x, y)


func _clamp_handle_pos(pos : Vector2) -> Vector2:
	var margins = _default_handle_size_hover / 2
	return pos.clamp(Vector2(margins, margins), Vector2(size.x - margins, size.y - margins))


## Remaps the current value to a handle position
func _get_handle_position() -> Vector2:
	return _value_to_handle_position(value)


## Gets the handle position and returns a Rect2 for drawing
func _get_handle_rect() -> Rect2:
	var pos = _get_handle_position()
	var handle_size = 10
	var handle_radius = 5
	
	return Rect2(pos.x - handle_radius, pos.y - handle_radius, handle_size, handle_size)
