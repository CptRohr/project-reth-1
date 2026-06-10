## Extended UI: HSlider
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io
## 
## NOTE: focus_mode should be set to "All" or "Click" for precision mode to work.
## 
## A powerful horizontal slider with support for:
## - shift key modifier to decrease cursor sensitivity for added precision
## - direct input by double-clicking
## - mouse wheel input to increase/decrease
## - reset-to-default by ctrl+clicking
@tool class_name XUIHSlider extends Range

## When disabled, all user interactions with the slider are blocked.
@export var editable := true

## When enabled, the value will snap to the clicked position within the slider.
@export var snap_to_clicked_position := true


# ====================================== #
# PRECISION MODE
# ====================================== #
@export_group("Precision", "precision")
enum PrecisionKey {
	CMD_CTRL,
	SHIFT,
	ALT_OPT
}

## Enables high-precision value adjustment by multiplying mouse movements by 0.1
@export var precision_enabled := true
@export var precision_key := PrecisionKey.SHIFT

# ====================================== #
# DEFAULT RESET
# ====================================== #
@export_group("Default", "default")

## When enabled, ctrl-clicking the slider will reset the slider to the given default value.
@export var default_reset_enabled := false

## When reset, slider value will be set to this value.
@export var default_value : float = 0.0

@export var default_key := PrecisionKey.CMD_CTRL


# ====================================== #
# SCROLL
# ====================================== #
@export_group("Scroll", "scroll")

## When enabled, hovering and scrolling up/down with the mouse wheel increases/decreases the value
@export var scroll_enabled := true
@export var scroll_step := 1.0


# ====================================== #
# EDIT
# ====================================== #
@export_group("Line Edit", "line_edit")
@export var line_edit_enabled := true


# ====================================== #
# CLIPBOARD
# ====================================== #
@export_group("Clipboard", "clipboard")
@export var clipboard_enabled := true

# ====================================== #
# LABEL
# ====================================== #
@export_group("Label", "label")

enum LabelVisibilityMode {
	ALWAYS,
	ON_HOVER,
	WHILE_ADJUSTING
}

## When enabled, shows the value as a label over the slider, with optional prefix and/or suffix.
@export var label_enabled := true
@export var label_mode := LabelVisibilityMode.ALWAYS
@export var label_prefix := "value: "
@export var label_suffix := "px"


# ====================================== #
# STATE
# ====================================== #
var _is_hovered := false

var _is_dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_value := 0.0

var _is_precision_dragging := false
var _precision_drag_start_mouse := Vector2.ZERO
var _precision_drag_start_value := 0.0

var _is_line_editing := false
var _line_edit_control : LineEdit
var _line_edit_original_value := 0.0

# ====================================== #
# LIFECYCLE
# ====================================== #
func _get_minimum_size() -> Vector2:
	return Vector2(32, 8)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	visibility_changed.connect(_on_visibility_changed)


# ====================================== #
# INPUT HANDLING
# ====================================== #
func _on_mouse_entered() -> void:
	_is_hovered = true
	if label_mode == LabelVisibilityMode.ON_HOVER:
		queue_redraw()

func _on_mouse_exited() -> void:
	_is_hovered = false
	if label_mode == LabelVisibilityMode.ON_HOVER:
		queue_redraw()

func _on_visibility_changed() -> void:
	if _is_line_editing and not is_visible_in_tree():
		_cancel_line_editing()

func _gui_input(event: InputEvent) -> void:
	if not editable:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP and scroll_enabled:
			_handle_scroll_up()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and scroll_enabled:
			_handle_scroll_down()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_command_or_control_pressed() and default_reset_enabled:
				_reset_to_default()
			if event.double_click and not _is_dragging:
				_handle_double_click()
			elif event.pressed and not _is_dragging:
				grab_click_focus()
				_start_dragging()
			elif event.is_released() and _is_dragging:
				_stop_dragging()
	elif event is InputEventMouseMotion:
		if _is_dragging:
			_update_dragging()
	elif event is InputEventKey:
		# Handle precision mode during dragging
		if _is_dragging and precision_enabled and event.keycode == _get_precision_keycode():
				if event.is_pressed():
					_start_precision_dragging()
				elif event.is_released():
					_stop_precision_dragging()


func _unhandled_input(event: InputEvent) -> void:
	# Handle clipboard operations when hovered (Blender-style)
	# This works without needing focus on the control
	if not editable:
		return
	
	if event is InputEventKey and clipboard_enabled and is_visible_in_tree() and _is_hovered and not _is_line_editing:
		if event.is_pressed() and event.is_command_or_control_pressed():
			if event.keycode == KEY_C:
				_copy_to_clipboard()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_V:
				_paste_from_clipboard()
				get_viewport().set_input_as_handled()


func _pixel_to_value(pixel : Vector2, clamp := false) -> float:
	var x = pixel.x
	
	var val := remap(x, 0, size.x, min_value, max_value)
	
	if clamp:
		val = clamp(val, min_value, max_value)
	
	return val

func _value_to_pixel(val : float, clamp := true) -> Vector2:
	var x := remap(val, min_value, max_value, 0, size.x)
	
	var pixel := Vector2(x, 0)
	if clamp:
		pixel = pixel.clamp(Vector2.ZERO, size)
	
	return pixel

func _start_dragging() -> void:
	_is_dragging = true
	
	_drag_start_mouse = get_local_mouse_position()
	
	if Input.is_key_pressed(_get_precision_keycode()):
		_start_precision_dragging()
	elif snap_to_clicked_position:
		value = _pixel_to_value(_drag_start_mouse)
	
	_drag_start_value = value
	
	
func _get_precision_keycode() -> int:
	match precision_key:
		PrecisionKey.CMD_CTRL:
			return KEY_CTRL
		PrecisionKey.SHIFT:
			return KEY_SHIFT
		_:
			return KEY_ALT

func _update_dragging() -> void:
	var mouse = get_local_mouse_position()
	var mouse_delta = mouse - _drag_start_mouse
	
	if _is_precision_dragging:
		var pixel = _value_to_pixel(_precision_drag_start_value)
		pixel.x += mouse_delta.x * 0.1
		var new_val = _pixel_to_value(pixel)
		value = new_val
	else:
		var pixel = _value_to_pixel(_drag_start_value)
		pixel.x += mouse_delta.x
		var new_val = _pixel_to_value(pixel)
		value = new_val


func _start_precision_dragging() -> void:
	_precision_drag_start_mouse = get_local_mouse_position()
	_precision_drag_start_value = value
	_is_precision_dragging = true

func _stop_precision_dragging() -> void:
	_drag_start_mouse = get_local_mouse_position()
	_drag_start_value = value
	_is_precision_dragging = false

func _stop_dragging() -> void:
	_is_dragging = false
	_is_precision_dragging = false
	queue_redraw()


func _handle_scroll_up() -> void:
	var s := scroll_step
	
	if precision_enabled:
		if Input.is_key_pressed(_get_precision_keycode()):
			s *= 0.1
	
	print("stepping up by ", s)
	
	value += s

func _handle_scroll_down() -> void:
	var s := scroll_step
	
	if precision_enabled:
		if Input.is_key_pressed(_get_precision_keycode()):
			s *= 0.1
	
	print("stepping down by ", s)
	
	value -= s

func _handle_double_click() -> void:
	_is_dragging = false
	_is_line_editing = true
	_start_line_editing()

func _create_line_edit_control() -> void:
	_line_edit_control = LineEdit.new()
	_line_edit_control.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line_edit_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_line_edit_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_line_edit_control.emoji_menu_enabled = false
	_line_edit_control.select_all_on_focus = true
	_line_edit_control.caret_blink = true
	_line_edit_control.caret_blink_interval = 0.3
	
	_line_edit_control.text_submitted.connect(_on_line_edit_text_submitted)
	_line_edit_control.editing_toggled.connect(_on_line_edit_editing_toggled)
	add_child(_line_edit_control)

func _start_line_editing() -> void:
	_line_edit_original_value = value
	
	if not _line_edit_control:
		_create_line_edit_control()
	
	_line_edit_control.text = str(value)
	_line_edit_control.placeholder_text = str(value)
	_line_edit_control.show()
	_line_edit_control.grab_focus()
	_line_edit_control.select_all()
	_line_edit_control.caret_column = _line_edit_control.text.length()
	
	_is_line_editing = true

func _on_line_edit_text_submitted(text : String) -> void:
	value = float(text.strip_edges())
	_stop_line_editing()

func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on and _is_line_editing:
		# Edit mode ended - cancel if we're still in editing state
		# (text_submitted will have already set _is_line_editing to false)
		_cancel_line_editing()

func _stop_line_editing() -> void:
	if _line_edit_control:
		if _line_edit_control.has_focus():
			_line_edit_control.release_focus()
		_line_edit_control.hide()
	
	_is_line_editing = false
	queue_redraw()

func _cancel_line_editing() -> void:
	value = _line_edit_original_value
	_stop_line_editing()


func _reset_to_default() -> void:
	value = default_value


# ====================================== #
# CLIPBOARD HELPERS
# ====================================== #
func _copy_to_clipboard() -> void:
	DisplayServer.clipboard_set(str(value))

func _paste_from_clipboard() -> void:
	var clipboard_text := DisplayServer.clipboard_get()
	var new_value := float(clipboard_text.strip_edges())
	
	# Validate that we got a valid number
	if clipboard_text.strip_edges().is_valid_float():
		value = clamp(new_value, min_value, max_value)


func _should_show_label() -> bool:
	if not label_enabled or _is_line_editing:
		return false
	
	if label_mode == LabelVisibilityMode.ALWAYS:
		return true
	elif label_mode == LabelVisibilityMode.ON_HOVER and _is_hovered or _is_dragging:
		return true
	elif label_mode == LabelVisibilityMode.WHILE_ADJUSTING and _is_dragging:
		return true
	
	return false


func _draw() -> void:
	_draw_slider()
	
	if _should_show_label():
		_draw_label()

func _draw_slider() -> void:
	var bg_style : StyleBox
	if has_theme_stylebox("slider"):
		bg_style = get_theme_stylebox("slider")
	else:
		bg_style = get_theme_stylebox("slider", "HSlider")
	
	var fill_style : StyleBox
	if has_theme_stylebox("grabber_highlight"):
		fill_style = get_theme_stylebox("grabber_area")
	else:
		fill_style = get_theme_stylebox("grabber_area", "HSlider")
	
	# draw background
	draw_style_box(bg_style, Rect2(0, 0, size.x, size.y))
	
	# draw fill
	var fill_factor = remap(value, min_value, max_value, 0, 1)
	var fill_width = size.x * fill_factor
	draw_style_box(fill_style, Rect2(0, 0, fill_width, size.y))

func _get_label_text() -> String:
	var text = label_prefix + str(value) + label_suffix
	return text

## Draws the value over the slider with optional prefix and suffix
func _draw_label() -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var text := _get_label_text()

	# Optional: use theme label colors instead of hardcoded.
	# Fallback to white if not present.
	var label_color := Color.WHITE
	if has_theme_color("font_color", "Label"):
		label_color = get_theme_color("font_color", "Label")

	# Use your slider's background stylebox to respect content margins
	var bg_style: StyleBox
	if has_theme_stylebox("slider"):
		bg_style = get_theme_stylebox("slider")
	else:
		bg_style = get_theme_stylebox("slider", "HSlider")

	var left   := bg_style.get_content_margin(SIDE_LEFT)
	var right  := bg_style.get_content_margin(SIDE_RIGHT)
	var top    := bg_style.get_content_margin(SIDE_TOP)
	var bottom := bg_style.get_content_margin(SIDE_BOTTOM)

	var box_pos := Vector2(left, top)
	var box_size := Vector2(size.x - left - right, size.y - top - bottom)

	# Vertical center: draw_string uses BASELINE Y.
	var font_h := font.get_height(font_size)
	var ascent := font.get_ascent(font_size)
	var baseline_y := box_pos.y + (box_size.y - font_h) * 0.5 + ascent

	# Horizontal center: alignment works only when width >= 0.
	# Use x = left edge of the box and width = box width.
	var draw_pos := Vector2(box_pos.x, baseline_y)
	draw_string(
		font,
		draw_pos,
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		box_size.x, # <-- critical
		font_size,
		label_color
	)
