## Extended UI: Barycentric Slider
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io
##
## A polygon-based slider for blending multiple factors using barycentric coordinates.
## Useful for character morphing systems, blend shapes, and multi-factor interpolation.
## 
## The handle can be placed anywhere within the polygon, with optional edge-snapping
## to ensure weights sum to exactly 1.0. Supports 3+ points and an optional center factor.
@tool class_name XUIBarycentricSlider extends Control

# ====================================== #
# SIGNALS
# ====================================== #
## Emitted when any weight changes. Dictionary maps point_name -> weight (0.0-1.0)
signal weights_changed(weights: Dictionary)

## Emitted when a specific point's weight changes
signal point_weight_changed(point_name: String, weight: float)


# ====================================== #
# CONFIGURATION
# ====================================== #
## When disabled, all user interactions with the slider are blocked
@export var editable := true

## Array of factors/vertices defining the polygon
@export var points: Array[BarycentricPoint] = []

## Current handle position (normalized within polygon bounds)
@export var handle_position := Vector2(0.5, 0.5):
	set(value):
		handle_position = value
		_update_weights()
		queue_redraw()


# ====================================== #
# DISPLAY
# ====================================== #
@export_group("Display", "display")

## When true, polygon stretches to fill control. When false, uses equilateral polygon
## based on smallest dimension to prevent distortion
@export var stretch := true:
	set(value):
		stretch = value
		queue_redraw()

## When enabled, shows point names as labels near each vertex
@export var show_labels := true:
	set(value):
		show_labels = value
		queue_redraw()

## Distance to offset labels from vertices
@export var label_offset := 15.0:
	set(value):
		label_offset = value
		queue_redraw()


# ====================================== #
# CENTER FACTOR
# ====================================== #
@export_group("Center Factor", "center")

## When enabled, the center acts as an additional independent factor
@export var center_enabled := false:
	set(value):
		center_enabled = value
		_update_weights()
		queue_redraw()

## Name for the center factor
@export var center_name := "Neutral"


# ====================================== #
# EDGE SNAP
# ====================================== #
@export_group("Edge Snap", "edge_snap")

## When enabled, handle is constrained to polygon edges, ensuring weights sum to 1.0
@export var edge_snap_enabled := false:
	set(value):
		edge_snap_enabled = value
		if value and _is_dragging:
			_apply_edge_snap()
		queue_redraw()


# ====================================== #
# STATE
# ====================================== #
var _weights: Dictionary = {}  # point_name -> weight (0.0-1.0)
var _polygon_vertices: PackedVector2Array = []  # Cached polygon vertices in control space
var _is_dragging := false
var _handle_hovered := false
var _drag_start_mouse := Vector2.ZERO


# ====================================== #
# LIFECYCLE
# ====================================== #
func _get_minimum_size() -> Vector2:
	var min_polygon_size := 32.0
	var margin := 10.0  # Base margin
	
	if show_labels and points.size() > 0:
		# Calculate margin needed for labels
		var font: Font = get_theme_default_font()
		var font_size: int = get_theme_default_font_size()
		var max_text_width = 0.0
		
		for point in points:
			var text_size = font.get_string_size(point.point_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			if text_size.x > max_text_width:
				max_text_width = text_size.x
		
		margin += label_offset + max_text_width / 2.0
	
	# Minimum control size = polygon size + margins on both sides
	var min_size = min_polygon_size + (margin * 2.0)
	return Vector2(min_size, min_size)

func _ready() -> void:
	_calculate_polygon_vertices()
	_update_weights()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# ====================================== #
# INPUT HANDLING
# ====================================== #
func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	if _handle_hovered and not _is_dragging:
		_handle_hovered = false
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not editable:
		return
	
	if event is InputEventMouseMotion:
		if _is_dragging:
			_update_dragging()
		else:
			# Update hover state when not dragging
			var handle_rect := _get_handle_rect()
			var mouse = event.position
			
			if not _handle_hovered and handle_rect.has_point(mouse):
				_handle_hovered = true
				queue_redraw()
			elif _handle_hovered and not handle_rect.has_point(mouse):
				_handle_hovered = false
				queue_redraw()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not _is_dragging:
				var handle_rect := _get_handle_rect()
				# If clicking on handle, start dragging without snapping
				if _handle_hovered or handle_rect.has_point(event.position):
					_start_dragging()
				# Otherwise, allow starting drag from anywhere within the polygon and snap to position
				elif _is_point_in_polygon(event.position):
					_start_dragging(event.position)
			elif event.is_released() and _is_dragging:
				_stop_dragging()


func _start_dragging(click_position: Vector2 = Vector2.ZERO) -> void:
	_is_dragging = true
	_drag_start_mouse = get_local_mouse_position()
	
	# Snap handle to clicked position if click was within polygon
	if click_position != Vector2.ZERO:
		handle_position = _screen_to_normalized(click_position)
		handle_position = _constrain_to_polygon(handle_position)
		
		# Apply edge snap if enabled
		if edge_snap_enabled:
			_apply_edge_snap()
		
		_update_weights()
		queue_redraw()

func _update_dragging() -> void:
	var mouse = get_local_mouse_position()
	
	# Update handle position
	handle_position = _screen_to_normalized(mouse)
	
	# Constrain to polygon
	handle_position = _constrain_to_polygon(handle_position)
	
	# Apply edge snap if enabled
	if edge_snap_enabled:
		_apply_edge_snap()
	
	_update_weights()
	queue_redraw()

func _stop_dragging() -> void:
	_is_dragging = false
	queue_redraw()


# ====================================== #
# POLYGON GEOMETRY
# ====================================== #
func _calculate_polygon_vertices() -> void:
	_polygon_vertices.clear()
	
	if points.size() < 3:
		return
	
	var center := size / 2.0
	var radius: float
	
	# Calculate margin needed for labels
	var margin := 10.0  # Base margin
	if show_labels:
		# Add space for label offset and approximate text size
		var font: Font = get_theme_default_font()
		var font_size: int = get_theme_default_font_size()
		var max_text_width = 0.0
		
		for point in points:
			var text_size = font.get_string_size(point.point_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			if text_size.x > max_text_width:
				max_text_width = text_size.x
		
		margin += label_offset + max_text_width / 2.0
	
	if stretch:
		# Use different radii for x and y, accounting for margins
		var radius_x = (size.x / 2.0) - margin
		var radius_y = (size.y / 2.0) - margin
		
		for i in points.size():
			var angle = (TAU * i / points.size()) - PI / 2  # Start at top
			var x = center.x + cos(angle) * radius_x
			var y = center.y + sin(angle) * radius_y
			_polygon_vertices.append(Vector2(x, y))
	else:
		# Equilateral polygon based on smallest dimension
		radius = min(size.x, size.y) / 2.0 - margin
		
		for i in points.size():
			var angle = (TAU * i / points.size()) - PI / 2  # Start at top
			var x = center.x + cos(angle) * radius
			var y = center.y + sin(angle) * radius
			_polygon_vertices.append(Vector2(x, y))

func _is_point_in_polygon(point: Vector2) -> bool:
	if _polygon_vertices.size() < 3:
		return false
	
	# Ray casting algorithm
	var inside = false
	var j = _polygon_vertices.size() - 1
	
	for i in _polygon_vertices.size():
		var vi = _polygon_vertices[i]
		var vj = _polygon_vertices[j]
		
		if ((vi.y > point.y) != (vj.y > point.y)) and \
		   (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = not inside
		
		j = i
	
	return inside

func _constrain_to_polygon(normalized_pos: Vector2) -> Vector2:
	var screen_pos = _normalized_to_screen(normalized_pos)
	
	if _is_point_in_polygon(screen_pos):
		return normalized_pos
	
	# Project to nearest point on polygon boundary
	var center = size / 2.0
	var direction = (screen_pos - center).normalized()
	
	# Find intersection with polygon edges
	var nearest_point = center
	var min_distance = INF
	
	for i in _polygon_vertices.size():
		var v1 = _polygon_vertices[i]
		var v2 = _polygon_vertices[(i + 1) % _polygon_vertices.size()]
		
		# Find intersection of ray from center through screen_pos with edge v1-v2
		var intersection = _ray_segment_intersection(center, direction, v1, v2)
		if intersection != Vector2.INF:
			var dist = center.distance_to(intersection)
			if dist < min_distance:
				min_distance = dist
				nearest_point = intersection
	
	return _screen_to_normalized(nearest_point)

func _ray_segment_intersection(ray_origin: Vector2, ray_dir: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
	var seg_dir = seg_b - seg_a
	var seg_len = seg_dir.length()
	
	if seg_len < 0.0001:
		return Vector2.INF
	
	seg_dir = seg_dir / seg_len
	
	# Solve: ray_origin + t1 * ray_dir = seg_a + t2 * seg_dir
	var cross = ray_dir.x * seg_dir.y - ray_dir.y * seg_dir.x
	
	if abs(cross) < 0.0001:
		# Parallel
		return Vector2.INF
	
	var diff = seg_a - ray_origin
	var t1 = (diff.x * seg_dir.y - diff.y * seg_dir.x) / cross
	var t2 = (diff.x * ray_dir.y - diff.y * ray_dir.x) / cross
	
	# Check if intersection is on the ray (t1 >= 0) and on the segment (0 <= t2 <= seg_len)
	if t1 >= 0 and t2 >= 0 and t2 <= seg_len:
		return ray_origin + ray_dir * t1
	
	return Vector2.INF

func _apply_edge_snap() -> void:
	# Snap handle to nearest edge
	var screen_pos = _normalized_to_screen(handle_position)
	var nearest_point = _find_nearest_edge_point(screen_pos)
	handle_position = _screen_to_normalized(nearest_point)

func _find_nearest_edge_point(point: Vector2) -> Vector2:
	if _polygon_vertices.size() < 2:
		return point
	
	var nearest_point = point
	var min_distance = INF
	
	# Check each edge
	for i in _polygon_vertices.size():
		var v1 = _polygon_vertices[i]
		var v2 = _polygon_vertices[(i + 1) % _polygon_vertices.size()]
		
		var edge_point = _closest_point_on_segment(point, v1, v2)
		var distance = point.distance_to(edge_point)
		
		if distance < min_distance:
			min_distance = distance
			nearest_point = edge_point
	
	return nearest_point

func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ap = point - a
	var t = ap.dot(ab) / ab.dot(ab)
	t = clampf(t, 0.0, 1.0)
	return a + ab * t


# ====================================== #
# COORDINATE CONVERSION
# ====================================== #
func _screen_to_normalized(screen_pos: Vector2) -> Vector2:
	return screen_pos / size

func _normalized_to_screen(normalized_pos: Vector2) -> Vector2:
	return normalized_pos * size

func _get_handle_screen_position() -> Vector2:
	return _normalized_to_screen(handle_position)

func _get_handle_rect() -> Rect2:
	var pos = _get_handle_screen_position()
	var handle_radius = 8.0
	return Rect2(pos.x - handle_radius, pos.y - handle_radius, handle_radius * 2, handle_radius * 2)


# ====================================== #
# BARYCENTRIC CALCULATION
# ====================================== #
func _update_weights() -> void:
	var old_weights = _weights.duplicate()
	_weights.clear()
	
	if points.size() < 3:
		return
	
	var screen_pos = _get_handle_screen_position()
	
	# Calculate barycentric coordinates
	if points.size() == 3:
		# Use standard barycentric for triangles
		_weights = _calculate_triangle_barycentric(screen_pos)
	else:
		# Use generalized barycentric for n-gons
		_weights = _calculate_generalized_barycentric(screen_pos)
	
	# Handle center factor if enabled
	if center_enabled:
		_add_center_weight(screen_pos)
	
	# Emit signals if weights changed
	_emit_weight_signals(old_weights)

func _calculate_triangle_barycentric(point: Vector2) -> Dictionary:
	if _polygon_vertices.size() != 3:
		return {}
	
	var v0 = _polygon_vertices[0]
	var v1 = _polygon_vertices[1]
	var v2 = _polygon_vertices[2]
	
	var denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y)
	
	if abs(denom) < 0.0001:
		# Degenerate triangle
		return {
			points[0].point_name: 1.0 / 3.0,
			points[1].point_name: 1.0 / 3.0,
			points[2].point_name: 1.0 / 3.0
		}
	
	var w0 = ((v1.y - v2.y) * (point.x - v2.x) + (v2.x - v1.x) * (point.y - v2.y)) / denom
	var w1 = ((v2.y - v0.y) * (point.x - v2.x) + (v0.x - v2.x) * (point.y - v2.y)) / denom
	var w2 = 1.0 - w0 - w1
	
	return {
		points[0].point_name: clampf(w0, 0.0, 1.0),
		points[1].point_name: clampf(w1, 0.0, 1.0),
		points[2].point_name: clampf(w2, 0.0, 1.0)
	}

func _calculate_generalized_barycentric(point: Vector2) -> Dictionary:
	# Mean value coordinates for arbitrary polygons
	var weights_dict = {}
	var weights_array = []
	var n = _polygon_vertices.size()
	
	# Calculate mean value coordinates
	for i in n:
		var v_prev = _polygon_vertices[(i - 1 + n) % n]
		var v_curr = _polygon_vertices[i]
		var v_next = _polygon_vertices[(i + 1) % n]
		
		var r_prev = (v_prev - point).length()
		var r_curr = (v_curr - point).length()
		var r_next = (v_next - point).length()
		
		# Handle case where point is on a vertex
		if r_curr < 0.0001:
			for j in n:
				weights_dict[points[j].point_name] = 1.0 if j == i else 0.0
			return weights_dict
		
		# Calculate angles
		var angle_prev = acos(clampf((v_prev - point).normalized().dot((v_curr - point).normalized()), -1.0, 1.0))
		var angle_next = acos(clampf((v_curr - point).normalized().dot((v_next - point).normalized()), -1.0, 1.0))
		
		var weight = (tan(angle_prev / 2.0) + tan(angle_next / 2.0)) / r_curr
		weights_array.append(weight)
	
	# Normalize weights
	var sum = 0.0
	for w in weights_array:
		sum += w
	
	if sum < 0.0001:
		# Fallback to equal weights
		for i in n:
			weights_dict[points[i].point_name] = 1.0 / n
	else:
		for i in n:
			weights_dict[points[i].point_name] = weights_array[i] / sum
	
	return weights_dict

func _add_center_weight(point: Vector2) -> void:
	var center = size / 2.0
	var dist_to_center = point.distance_to(center)
	
	# Calculate max radius (distance to farthest vertex from center)
	var max_radius = 0.0
	for vertex in _polygon_vertices:
		var dist = center.distance_to(vertex)
		if dist > max_radius:
			max_radius = dist
	
	if max_radius < 0.0001:
		return
	
	# Center weight is inversely proportional to distance from center
	var center_weight = 1.0 - clampf(dist_to_center / max_radius, 0.0, 1.0)
	
	# Scale other weights down
	var scale = 1.0 - center_weight
	for key in _weights.keys():
		_weights[key] *= scale
	
	_weights[center_name] = center_weight

func _emit_weight_signals(old_weights: Dictionary) -> void:
	# Emit individual weight changes
	for point_name in _weights.keys():
		var new_weight = _weights.get(point_name, 0.0)
		var old_weight = old_weights.get(point_name, 0.0)
		
		if not is_equal_approx(new_weight, old_weight):
			point_weight_changed.emit(point_name, new_weight)
	
	# Always emit weights_changed
	weights_changed.emit(_weights)


# ====================================== #
# DRAW FUNCTIONS
# ====================================== #
func _draw() -> void:
	_calculate_polygon_vertices()
	
	if _polygon_vertices.size() < 3:
		return
	
	#_draw_background()
	_draw_polygon()

	if center_enabled:
		_draw_center_point()
	
	if show_labels:
		_draw_labels()
	
	_draw_handle()

func _draw_background() -> void:
	var bg_style: StyleBox
	if has_theme_stylebox("slider"):
		bg_style = get_theme_stylebox("slider")
	else:
		bg_style = get_theme_stylebox("slider", "HSlider")
	
	draw_style_box(bg_style, Rect2(0, 0, size.x, size.y))

func _draw_polygon() -> void:
	# Draw polygon fill
	var fill_color := Color(0.2, 0.2, 0.2, 0.5)
	if has_theme_color("polygon_fill"):
		fill_color = get_theme_color("polygon_fill")
	
	draw_colored_polygon(_polygon_vertices, fill_color)
	
	# Draw polygon outline
	var outline_color := Color(0.5, 0.5, 0.5, 1.0)
	if has_theme_color("polygon_outline"):
		outline_color = get_theme_color("polygon_outline")
	
	var outline_width := 2.0
	if has_theme_constant("polygon_outline_width"):
		outline_width = get_theme_constant("polygon_outline_width")
	
	for i in _polygon_vertices.size():
		var v1 = _polygon_vertices[i]
		var v2 = _polygon_vertices[(i + 1) % _polygon_vertices.size()]
		draw_line(v1, v2, outline_color, outline_width, true)

func _draw_center_point() -> void:
	if not center_enabled:
		return
	
	var center = size / 2.0
	var center_radius := 4.0
	var center_color := Color(0.7, 0.7, 0.7, 0.8)
	
	if has_theme_constant("center_radius"):
		center_radius = get_theme_constant("center_radius")
	if has_theme_color("center_color"):
		center_color = get_theme_color("center_color")
	
	draw_circle(center, center_radius, center_color, true, -1.0, true)

func _draw_handle() -> void:
	var handle_pos = _get_handle_screen_position()
	
	var handle_color := Color(1.0, 1.0, 1.0, 0.9)
	if _handle_hovered or _is_dragging:
		handle_color = Color(1.0, 1.0, 1.0, 1.0)
	
	if has_theme_color("handle_color"):
		handle_color = get_theme_color("handle_color")
	
	var handle_radius := 6.0
	if _handle_hovered or _is_dragging:
		handle_radius = 8.0
	
	if has_theme_constant("handle_radius"):
		handle_radius = get_theme_constant("handle_radius")
	
	# Draw handle with outline
	draw_circle(handle_pos, handle_radius + 1, Color(0, 0, 0, 0.5), true, -1.0, true)
	draw_circle(handle_pos, handle_radius, handle_color, true, -1.0, true)

func _draw_labels() -> void:
	if points.size() < 3:
		return
	
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	
	var label_color := Color.WHITE
	if has_theme_color("font_color", "Label"):
		label_color = get_theme_color("font_color", "Label")
	
	var center = size / 2.0
	
	for i in points.size():
		var point = points[i]
		var vertex = _polygon_vertices[i]
		
		# Calculate direction from center to vertex
		var direction = (vertex - center).normalized()
		
		# Base label position: vertex + offset in direction
		var label_pos = vertex + direction * label_offset
		
		# Get text dimensions
		var text = point.point_name
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		
		# Determine alignment based on direction vector
		var horizontal_align = HORIZONTAL_ALIGNMENT_CENTER
		
		# Use the horizontal component of direction to determine alignment
		# Threshold for "mostly horizontal" vs "mostly vertical"
		var h_threshold = 0.5
		
		if abs(direction.x) > h_threshold:
			# Mostly horizontal direction
			if direction.x > 0:
				# Pointing right - align left
				horizontal_align = HORIZONTAL_ALIGNMENT_LEFT
			else:
				# Pointing left - align right
				horizontal_align = HORIZONTAL_ALIGNMENT_RIGHT
				label_pos.x -= text_size.x
		else:
			# Mostly vertical direction (up or down) - keep centered
			horizontal_align = HORIZONTAL_ALIGNMENT_CENTER
			label_pos.x -= text_size.x / 2.0
		
		# Vertical centering
		label_pos.y += text_size.y / 4.0
		
		# Draw label
		draw_string(
			font,
			label_pos,
			text,
			horizontal_align,
			-1,
			font_size,
			label_color
		)


# ====================================== #
# PUBLIC API
# ====================================== #
## Get the current weights dictionary
func get_weights() -> Dictionary:
	return _weights.duplicate()

## Get weight for a specific point
func get_weight(point_name: String) -> float:
	return _weights.get(point_name, 0.0)
