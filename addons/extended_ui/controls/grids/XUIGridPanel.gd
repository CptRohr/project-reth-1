## Extended UI: Grid Panel
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io

## A panel that displays a 2D grid of major with optional minor grid subdivision lines.
@tool
class_name XUIGridPanel
extends Control

#===========================================
# SETTINGS
#===========================================

## The spacing between major grid lines.
@export var major_grid_size: int = 16:
	set(v):
		major_grid_size = max(1, v)
		queue_redraw()

## Whether to show minor grid lines.
@export var minor_grid_lines_visible: bool = true:
	set(v):
		minor_grid_lines_visible = v
		queue_redraw()

## The spacing between minor grid lines.
@export var minor_grid_size: int = 8:
	set(v):
		minor_grid_size = max(1, v)
		queue_redraw()

## Offset to apply to grid positioning.
@export var offset: Vector2 = Vector2.ZERO:
	set(v):
		offset = v
		queue_redraw()

## When enabled, the grid is placed relative to the center of the control rather than the top-left corner.
@export var centered: bool = false:
	set(v):
		centered = v
		queue_redraw()

#===========================================
# THEMEING
# Theme items used by this control:
# - major_grid_color (Color)
# - minor_grid_color (Color)
# - major_grid_thickness (int/float via constant)
# - minor_grid_thickness (int/float via constant)
#===========================================

func _apply_theme_overrides() -> void:
	# Apply or remove theme overrides based on enabled state.
	# add_theme_*_override() will update existing overrides, so we don't need to check if they exist.
	
	# Major grid color
	if theme_override_major_grid_color_on:
		add_theme_color_override("major_grid_color", theme_override_major_grid_color)
	else:
		remove_theme_color_override("major_grid_color")
	
	# Minor grid color
	if theme_override_minor_grid_color_on:
		add_theme_color_override("minor_grid_color", theme_override_minor_grid_color)
	else:
		remove_theme_color_override("minor_grid_color")
	
	# Major grid thickness
	if theme_override_major_grid_thickness_on:
		add_theme_constant_override("major_grid_thickness", theme_override_major_grid_thickness)
	else:
		remove_theme_constant_override("major_grid_thickness")
	
	# Minor grid thickness
	if theme_override_minor_grid_thickness_on:
		add_theme_constant_override("minor_grid_thickness", theme_override_minor_grid_thickness)
	else:
		remove_theme_constant_override("minor_grid_thickness")

	queue_redraw()

@export_group("Theme", "theme_override")

@export var theme_override_major_grid_color_on: bool = false:
	set(v):
		theme_override_major_grid_color_on = v
		_apply_theme_overrides()

@export var theme_override_major_grid_color: Color = Color(0.4, 0.6, 1.0):
	set(v):
		theme_override_major_grid_color = v
		# Apply immediately if enabled
		if theme_override_major_grid_color_on:
			_apply_theme_overrides()

@export var theme_override_minor_grid_color_on: bool = false:
	set(v):
		theme_override_minor_grid_color_on = v
		_apply_theme_overrides()

@export var theme_override_minor_grid_color: Color = Color(0.4, 0.6, 1.0, 0.5):
	set(v):
		theme_override_minor_grid_color = v
		if theme_override_minor_grid_color_on:
			_apply_theme_overrides()

@export var theme_override_major_grid_thickness_on: bool = false:
	set(v):
		theme_override_major_grid_thickness_on = v
		_apply_theme_overrides()

@export var theme_override_major_grid_thickness: int = 1:
	set(v):
		theme_override_major_grid_thickness = max(1, v)
		if theme_override_major_grid_thickness_on:
			_apply_theme_overrides()

@export var theme_override_minor_grid_thickness_on: bool = false:
	set(v):
		theme_override_minor_grid_thickness_on = v
		_apply_theme_overrides()

@export var theme_override_minor_grid_thickness: int = 1:
	set(v):
		theme_override_minor_grid_thickness = max(1, v)
		if theme_override_minor_grid_thickness_on:
			_apply_theme_overrides()

func _ready() -> void:
	_apply_theme_overrides()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		# Theme changed upstream; redraw with new values.
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	# Defaults if nothing is provided by theme
	var major_color := Color(1.0, 1.0, 1.0, 0.5)
	var minor_color := Color(1.0, 1.0, 1.0, 0.2)

	# If you have a Theme with these custom items (either local override or theme resource),
	# Godot will resolve them. For custom items, specify a theme type if you use one.
	# If you don't use custom theme types, get_theme_color("name") is fine.
	if has_theme_color("major_grid_color"):
		major_color = get_theme_color("major_grid_color")
	if has_theme_color("minor_grid_color"):
		minor_color = get_theme_color("minor_grid_color")

	var major_thickness := 1.0
	var minor_thickness := 1.0
	if has_theme_constant("major_grid_thickness"):
		major_thickness = float(get_theme_constant("major_grid_thickness"))
	if has_theme_constant("minor_grid_thickness"):
		minor_thickness = float(get_theme_constant("minor_grid_thickness"))

	var origin := Vector2.ZERO
	if centered:
		origin = rect.size * 0.5
	origin += offset

	# Draw minor grid first (behind)
	if minor_grid_lines_visible and minor_grid_size > 0:
		_draw_grid(rect, origin, minor_grid_size, minor_color, minor_thickness)

	# Draw major grid on top
	if major_grid_size > 0:
		_draw_grid(rect, origin, major_grid_size, major_color, major_thickness)

func _draw_grid(rect: Rect2, origin: Vector2, step: int, col: Color, thickness: float) -> void:
	if step <= 0:
		return

	var w := rect.size.x
	var h := rect.size.y

	# We want lines at positions where (pos - origin) is a multiple of step.
	# Compute starting x and y within the visible rect.
	var start_x := _first_line_pos(0.0, origin.x, float(step))
	var start_y := _first_line_pos(0.0, origin.y, float(step))

	var x := start_x
	while x <= w:
		draw_line(Vector2(x, 0.0), Vector2(x, h), col, thickness, true)
		x += float(step)

	var y := start_y
	while y <= h:
		draw_line(Vector2(0.0, y), Vector2(w, y), col, thickness, true)
		y += float(step)

#===========================================
# PUBLIC API
#===========================================

## Snaps a position (in local control coordinates) to the nearest grid point.
## Takes into account the grid's origin, offset, and centered settings.
## [param use_major]: If true, snaps to major grid. If false, snaps to minor grid.
func snap_to_grid(pos: Vector2, use_major: bool = true) -> Vector2:
	var grid_size := major_grid_size if use_major else minor_grid_size
	
	if grid_size <= 0:
		return pos
	
	# Calculate grid origin
	var origin := Vector2.ZERO
	if centered:
		origin = size * 0.5
	origin += offset
	
	# Snap to nearest grid point
	var step := float(grid_size)
	var snapped_x = origin.x + round((pos.x - origin.x) / step) * step
	var snapped_y = origin.y + round((pos.y - origin.y) / step) * step
	
	return Vector2(snapped_x, snapped_y)

#===========================================
# HELPERS
#===========================================

func _first_line_pos(min_pos: float, origin_axis: float, step: float) -> float:
	# Find smallest p >= min_pos such that (p - origin_axis) % step == 0
	# Equivalent: p = origin_axis + ceil((min_pos - origin_axis)/step)*step
	var t := (min_pos - origin_axis) / step
	return origin_axis + ceil(t) * step
