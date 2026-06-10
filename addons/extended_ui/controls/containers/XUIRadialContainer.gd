## Extended UI: Radial Container
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io
##
## A container that lays out child controls in an arc or full circle.
## By default uses container size as-is (ellipse); optional square aspect uses circle = min(size.x, size.y).
## Sizing: place at minimum size first, then distribute extra space only to children with expand size flags.
@tool
class_name XUIRadialContainer
extends Container

# ====================================== #
# CONFIGURATION
# ====================================== #

enum AngleDistribution {
	## Place each child with equal angular distance across the arc (first at start, last at end of arc_angle).
	EQUAL,
	## Same as EQUAL: step is computed from arc_angle and child count so the arc is spanned.
	SEQUENTIAL
}

@export_group("Layout", "layout")
## How to distribute children along the arc.
@export var angle_distribution: AngleDistribution = AngleDistribution.EQUAL:
	set(v):
		angle_distribution = v
		queue_sort()

## Arc span in degrees (e.g. 360 = full circle, 180 = half). Used when angle_distribution is EQUAL.
@export var arc_angle: float = 360.0:
	set(v):
		arc_angle = clampf(v, 0.001, 360.0)
		queue_sort()

## Angle offset for the first slot in degrees (0 = right/east).
@export var rotation_offset: float = 0.0:
	set(v):
		rotation_offset = v
		queue_sort()

## Number of layout slots. -1 = auto (use child count). If > child count, extra slots are empty. When >= 0, also defines how many items are visible per page.
@export var slots: int = -1:
	set(v):
		slots = v
		queue_sort()

## Current page when slots >= 0 (0-based). Only children in the range [page*slots, (page+1)*slots) are visible and laid out.
@export var page: int = 0:
	set(v):
		page = v
		queue_sort()

## When false (default): use container inner size as-is (ellipse). When true: circle radius = min(inner_w, inner_h) / 2.
@export var square_aspect: bool = false:
	set(v):
		square_aspect = v
		queue_sort()

## Inner margin from container edge in pixels (x = horizontal inset, y = vertical inset; applied to all sides).
@export var margin: Vector2 = Vector2.ZERO:
	set(v):
		margin = v
		queue_sort()

# ====================================== #
# STATE
# ====================================== #

# (none required)

# ====================================== #
# LIFECYCLE
# ====================================== #

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()

# ====================================== #
# LAYOUT
# ====================================== #

func _get_minimum_size() -> Vector2:
	var layout_children := _get_layout_children()
	var ins := _get_margin_vec()
	if layout_children.is_empty():
		return Vector2(ins.x * 2.0, ins.y * 2.0)
	var effective_slots_count := _get_effective_slots(layout_children.size())
	if effective_slots_count <= 0:
		return Vector2(ins.x * 2.0, ins.y * 2.0)
	var visible_range := _get_visible_range(layout_children.size())
	var visible_start: int = visible_range.x
	var visible_end: int = visible_range.y
	var placed_count: int = visible_end - visible_start
	if placed_count <= 0:
		return Vector2(ins.x * 2.0, ins.y * 2.0)
	var rot_rad := deg_to_rad(rotation_offset)
	var angle_step: float = _get_angle_step_rad(effective_slots_count)
	var rx := 100.0
	var ry := 100.0
	if square_aspect:
		var r := minf(rx, ry)
		rx = r
		ry = r
	var center := Vector2.ZERO
	var first_point := _angle_to_position(center, rot_rad, rx, ry)
	var first_sz := (layout_children[visible_start] as Control).get_combined_minimum_size()
	var min_rect := Rect2(first_point - first_sz * 0.5, first_sz)
	for k in range(1, placed_count):
		var angle_rad: float = rot_rad + _get_angle_for_index(k, angle_step)
		var point := _angle_to_position(center, angle_rad, rx, ry)
		var child: Control = layout_children[visible_start + k]
		var min_sz := child.get_combined_minimum_size()
		var rect := Rect2(point - min_sz * 0.5, min_sz)
		min_rect = min_rect.expand(rect.position)
		min_rect = min_rect.expand(rect.end)
	return min_rect.size + Vector2(ins.x * 2.0, ins.y * 2.0)

func _sort_children() -> void:
	var layout_children := _get_layout_children()
	if layout_children.is_empty():
		return
	var effective_slots_count := _get_effective_slots(layout_children.size())
	if effective_slots_count <= 0:
		return

	var visible_range := _get_visible_range(layout_children.size())
	var visible_start: int = visible_range.x
	var visible_end: int = visible_range.y
	var placed_count: int = visible_end - visible_start

	# Hide children not on the current page; show visible ones
	for i in layout_children.size():
		layout_children[i].visible = (i >= visible_start and i < visible_end)

	if placed_count <= 0:
		return

	var inner_rect := _get_inner_rect()
	if inner_rect.size.x <= 0.0 or inner_rect.size.y <= 0.0:
		return
	var center := inner_rect.get_center()
	var inner_size := inner_rect.size

	# Calculate maximum half-size of children to ensure items stay within bounds
	var max_half_w := 0.0
	var max_half_h := 0.0
	for k in placed_count:
		var child: Control = layout_children[visible_start + k]
		var min_sz := child.get_combined_minimum_size()
		max_half_w = maxf(max_half_w, min_sz.x * 0.5)
		max_half_h = maxf(max_half_h, min_sz.y * 0.5)

	# Reduce radii by max half-size so items don't extend beyond container
	var rx := maxf(0.0, inner_size.x * 0.5 - max_half_w)
	var ry := maxf(0.0, inner_size.y * 0.5 - max_half_h)
	if square_aspect:
		var r := minf(rx, ry)
		rx = r
		ry = r

	var rot_rad := deg_to_rad(rotation_offset)
	var angle_step: float = _get_angle_step_rad(effective_slots_count)

	# Phase 1: positions and minimum sizes (only for visible children; use slot index 0..placed_count-1)
	var child_rects: Array[Rect2] = []
	child_rects.resize(placed_count)
	for k in placed_count:
		var angle_rad: float = rot_rad + _get_angle_for_index(k, angle_step)
		var point := _angle_to_position(center, angle_rad, rx, ry)
		var child: Control = layout_children[visible_start + k]
		var min_sz := child.get_combined_minimum_size()
		child_rects[k] = Rect2(point - min_sz * 0.5, min_sz)

	# Phase 2: distribute extra space only to children with expand flags
	var expand_h_count := 0
	var expand_v_count := 0
	for k in placed_count:
		var child: Control = layout_children[visible_start + k]
		if (child.size_flags_horizontal & Control.SIZE_EXPAND) != 0:
			expand_h_count += 1
		if (child.size_flags_vertical & Control.SIZE_EXPAND) != 0:
			expand_v_count += 1

	if expand_h_count > 0 or expand_v_count > 0:
		var total_min_w := 0.0
		var total_min_h := 0.0
		for r in child_rects:
			total_min_w += r.size.x
			total_min_h += r.size.y
		var extra_w := maxf(0.0, inner_size.x - total_min_w)
		var extra_h := maxf(0.0, inner_size.y - total_min_h)
		var add_w := extra_w / expand_h_count if expand_h_count > 0 else 0.0
		var add_h := extra_h / expand_v_count if expand_v_count > 0 else 0.0
		for k in placed_count:
			var child: Control = layout_children[visible_start + k]
			var r := child_rects[k]
			var new_size := r.size
			if (child.size_flags_horizontal & Control.SIZE_EXPAND) != 0:
				new_size.x = r.size.x + add_w
			if (child.size_flags_vertical & Control.SIZE_EXPAND) != 0:
				new_size.y = r.size.y + add_h
			child_rects[k] = Rect2(r.position + (r.size - new_size) * 0.5, new_size)

	for k in placed_count:
		fit_child_in_rect(layout_children[visible_start + k], child_rects[k])

# ====================================== #
# HELPERS
# ====================================== #

func _get_layout_children() -> Array[Control]:
	var out: Array[Control] = []
	for i in get_child_count():
		var node := get_child(i)
		if node is Control:
			out.append(node as Control)
	return out

func _get_effective_slots(child_count: int) -> int:
	if slots >= 0:
		return slots
	return child_count

func _get_visible_range(child_count: int) -> Vector2i:
	if slots < 0:
		return Vector2i(0, child_count)
	var max_page: int = maxi(0, (child_count - 1) / slots) if slots > 0 else 0
	var clamped_page: int = clampi(page, 0, max_page)
	var visible_start: int = clamped_page * slots
	var visible_end: int = mini(visible_start + slots, child_count)
	return Vector2i(visible_start, visible_end)

func _get_angle_step_rad(slot_count: int) -> float:
	var arc_rad: float = deg_to_rad(arc_angle)
	# Full circle (360°): step = arc / slot_count so no wrap.
	if arc_angle >= 359.99:
		return arc_rad / max(1, slot_count)
	# Arc < 360°: span full arc. Step between slot positions = arc_angle / (slot_count - 1).
	return arc_rad / max(1, slot_count - 1)

func _get_angle_for_index(slot_index: int, angle_step_rad: float) -> float:
	return float(slot_index) * angle_step_rad

func _get_margin_vec() -> Vector2:
	return margin

func _get_inner_rect() -> Rect2:
	var ins := _get_margin_vec()
	return Rect2(ins.x, ins.y, size.x - 2.0 * ins.x, size.y - 2.0 * ins.y)

func _angle_to_position(center: Vector2, angle_rad: float, radius_x: float, radius_y: float) -> Vector2:
	return center + Vector2(radius_x * cos(angle_rad), radius_y * sin(angle_rad))

func _get_allowed_size_flags_horizontal() -> PackedInt32Array:
	return PackedInt32Array([Control.SIZE_FILL, Control.SIZE_EXPAND, Control.SIZE_EXPAND_FILL, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_END])

func _get_allowed_size_flags_vertical() -> PackedInt32Array:
	return PackedInt32Array([Control.SIZE_FILL, Control.SIZE_EXPAND, Control.SIZE_EXPAND_FILL, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_END])
