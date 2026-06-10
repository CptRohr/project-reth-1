## Extended UI: View Container
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io
##
## A container that displays only one child at a time with optional animated transitions.
## Supports fade, crossfade, and slide transitions with configurable duration and easing.
@tool
class_name XUIViewContainer
extends Container

# ====================================== #
# CONFIGURATION
# ====================================== #

enum TransitionType {
	## No animation, immediate switch
	INSTANT,
	## Fade out old view, then fade in new view
	FADE,
	## Simultaneous fade out/in (crossfade)
	CROSSFADE,
	## Slides horizontally (direction based on index change)
	SLIDE_HORIZONTAL,
	## Slides vertically (direction based on index change)
	SLIDE_VERTICAL
}

@export_group("View", "view")
## Initial child index to display on ready
@export var initial_index := 0:
	set(v):
		initial_index = clampi(v, 0, 0 if get_child_count() == 0 else get_child_count() - 1)
		if not is_node_ready():
			return
		_switch_immediate(initial_index)

@export_group("Transitions", "transition")
## Enable transitions between views
@export var transition_enabled := true:
	set(v):
		transition_enabled = v

## Type of transition animation
@export var transition_type: TransitionType = TransitionType.FADE:
	set(v):
		transition_type = v

## Duration of transition in seconds
@export var transition_duration := 0.3:
	set(v):
		transition_duration = maxf(v, 0.0)

## Easing type for transition
@export var transition_easing: Tween.EaseType = Tween.EASE_IN_OUT:
	set(v):
		transition_easing = v

## Transition type for transition
@export var transition_trans: Tween.TransitionType = Tween.TRANS_CUBIC:
	set(v):
		transition_trans = v

# ====================================== #
# SIGNALS
# ====================================== #

## Emitted when starting a view switch (before transition)
signal view_changing(from_index: int, to_index: int)

## Emitted during transition with progress 0.0-1.0
signal view_transition_progress(progress: float)

# ====================================== #
# STATE
# ====================================== #

var _current_index: int = -1
var _is_transitioning: bool = false
var _current_tween: Tween = null

# ====================================== #
# LIFECYCLE
# ====================================== #

func _ready() -> void:
	_switch_immediate(initial_index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()

# ====================================== #
# NAVIGATION
# ====================================== #

## Switch to view at given index
func switch_to(index: int) -> void:
	var children := _get_layout_children()
	if children.is_empty():
		return
	
	var clamped_index := clampi(index, 0, children.size() - 1)
	if clamped_index == _current_index:
		return
	
	_switch_to_index(clamped_index)

## Switch to a specific child control
func switch_to_child(child: Control) -> void:
	var children := _get_layout_children()
	var index := children.find(child)
	if index >= 0:
		switch_to(index)

## Switch to next view (wraps around to first)
func next() -> void:
	var children := _get_layout_children()
	if children.is_empty():
		return
	
	var next_index := (_current_index + 1) % children.size()
	_switch_to_index(next_index)

## Switch to previous view (wraps around to last)
func previous() -> void:
	var children := _get_layout_children()
	if children.is_empty():
		return
	
	var prev_index := (_current_index - 1 + children.size()) % children.size()
	_switch_to_index(prev_index)

## Get current view index
func get_current_index() -> int:
	return _current_index

## Get current visible child
func get_current_child() -> Control:
	var children := _get_layout_children()
	if _current_index >= 0 and _current_index < children.size():
		return children[_current_index]
	return null

## Check if currently transitioning
func is_transitioning() -> bool:
	return _is_transitioning

# ====================================== #
# TRANSITIONS
# ====================================== #

func _switch_to_index(to_index: int) -> void:
	var children := _get_layout_children()
	if to_index < 0 or to_index >= children.size():
		return
	
	var from_index := _current_index
	
	# Kill existing tween
	if _current_tween:
		_current_tween.kill()
		_current_tween = null
	
	# Emit signal
	view_changing.emit(from_index, to_index)
	
	# If transitions disabled or instant, just switch immediately
	if not transition_enabled or transition_type == TransitionType.INSTANT or transition_duration <= 0.0:
		_switch_immediate(to_index)
		return
	
	# Start transition
	_is_transitioning = true
	
	match transition_type:
		TransitionType.FADE:
			_transition_fade(from_index, to_index, children)
		TransitionType.CROSSFADE:
			_transition_crossfade(from_index, to_index, children)
		TransitionType.SLIDE_HORIZONTAL:
			_transition_slide(from_index, to_index, children, true)
		TransitionType.SLIDE_VERTICAL:
			_transition_slide(from_index, to_index, children, false)

func _switch_immediate(to_index: int) -> void:
	var children := _get_layout_children()
	if children.is_empty():
		_current_index = -1
		return
	
	var clamped_index := clampi(to_index, 0, children.size() - 1)
	
	# Hide all children except target
	for i in children.size():
		var child := children[i]
		child.visible = (i == clamped_index)
		child.modulate.a = 1.0
		child.position = Vector2.ZERO
	
	_current_index = clamped_index
	_is_transitioning = false
	
	queue_sort()

func _transition_fade(from_index: int, to_index: int, children: Array[Control]) -> void:
	var old_child: Control = children[from_index] if from_index >= 0 and from_index < children.size() else null
	var new_child: Control = children[to_index]
	
	# Setup: new child invisible, old child visible
	if old_child:
		old_child.visible = true
		old_child.modulate.a = 1.0
	new_child.visible = true
	new_child.modulate.a = 0.0
	
	_current_tween = create_tween()
	_current_tween.set_ease(transition_easing)
	_current_tween.set_trans(transition_trans)
	
	# Fade out old, then fade in new
	if old_child:
		_current_tween.tween_property(old_child, "modulate:a", 0.0, transition_duration * 0.5)
		_current_tween.tween_callback(func(): old_child.visible = false)
	
	_current_tween.tween_property(new_child, "modulate:a", 1.0, transition_duration * 0.5)
	
	# Progress tracking
	_current_tween.tween_callback(func(): _on_transition_complete(to_index))

func _transition_crossfade(from_index: int, to_index: int, children: Array[Control]) -> void:
	var old_child: Control = children[from_index] if from_index >= 0 and from_index < children.size() else null
	var new_child: Control = children[to_index]
	
	# Setup
	if old_child:
		old_child.visible = true
		old_child.modulate.a = 1.0
	new_child.visible = true
	new_child.modulate.a = 0.0
	
	_current_tween = create_tween()
	_current_tween.set_ease(transition_easing)
	_current_tween.set_trans(transition_trans)
	_current_tween.set_parallel(true)
	
	# Simultaneous fade out/in
	if old_child:
		_current_tween.tween_property(old_child, "modulate:a", 0.0, transition_duration)
	_current_tween.tween_property(new_child, "modulate:a", 1.0, transition_duration)
	
	_current_tween.set_parallel(false)
	if old_child:
		_current_tween.tween_callback(func(): old_child.visible = false)
	
	_current_tween.tween_callback(func(): _on_transition_complete(to_index))

func _transition_slide(from_index: int, to_index: int, children: Array[Control], horizontal: bool) -> void:
	var old_child: Control = children[from_index] if from_index >= 0 and from_index < children.size() else null
	var new_child: Control = children[to_index]
	
	# Determine direction: negative = forward/next (slide left/up), positive = backward/prev (slide right/down)
	var direction := -1 if to_index > from_index else 1
	
	# Calculate slide distance
	var slide_offset := Vector2.ZERO
	if horizontal:
		slide_offset = Vector2(size.x * direction, 0)
	else:
		slide_offset = Vector2(0, size.y * direction)
	
	# Setup positions - both children must be visible and positioned before tween starts
	if old_child:
		old_child.visible = true
		old_child.modulate.a = 1.0
		old_child.position = Vector2.ZERO
	
	new_child.visible = true
	new_child.modulate.a = 1.0
	new_child.position = -slide_offset  # Start off-screen on opposite side
	
	# Create tween with both animations running in parallel
	_current_tween = create_tween()
	_current_tween.set_ease(transition_easing)
	_current_tween.set_trans(transition_trans)
	_current_tween.set_parallel(true)
	
	# Slide both children simultaneously
	if old_child:
		_current_tween.tween_property(old_child, "position", slide_offset, transition_duration)
	_current_tween.tween_property(new_child, "position", Vector2.ZERO, transition_duration)
	
	# Switch back to sequential for cleanup callbacks
	_current_tween.set_parallel(false)
	
	# Cleanup
	if old_child:
		_current_tween.tween_callback(func():
			old_child.visible = false
			old_child.position = Vector2.ZERO
		)
	
	_current_tween.tween_callback(func(): _on_transition_complete(to_index))

func _on_transition_complete(to_index: int) -> void:
	_current_index = to_index
	_is_transitioning = false
	_current_tween = null
	view_transition_progress.emit(1.0)
	queue_sort()

# ====================================== #
# LAYOUT
# ====================================== #

func _get_minimum_size() -> Vector2:
	var children := _get_layout_children()
	if children.is_empty():
		return Vector2.ZERO
	
	# Return the minimum size of the currently visible child
	# This allows the container to resize when switching views
	var active_index := _current_index if _current_index >= 0 else initial_index
	active_index = clampi(active_index, 0, children.size() - 1)
	
	return children[active_index].get_combined_minimum_size()

func _sort_children() -> void:
	var children := _get_layout_children()
	if children.is_empty():
		return
	
	# Use initial_index if _current_index hasn't been set yet (happens before _ready())
	var active_index := _current_index if _current_index >= 0 else initial_index
	active_index = clampi(active_index, 0, children.size() - 1)
	
	# Only enforce visibility if NOT transitioning (let the transition manage visibility)
	if not _is_transitioning:
		for i in children.size():
			children[i].visible = (i == active_index)
	
	var container_rect := Rect2(Vector2.ZERO, size)
	
	# During transitions, preserve child positions (don't call fit_child_in_rect which resets position)
	if _is_transitioning:
		# Only update size, preserve position
		for child in children:
			var preserved_pos := child.position
			fit_child_in_rect(child, container_rect)
			child.position = preserved_pos
	else:
		# Normal layout - fit children to container rect
		for child in children:
			fit_child_in_rect(child, container_rect)

# ====================================== #
# HELPERS
# ====================================== #

func _get_layout_children() -> Array[Control]:
	var out: Array[Control] = []
	for i in get_child_count():
		var node := get_child(i)
		if node is Control and not node.is_set_as_top_level():
			out.append(node as Control)
	return out
