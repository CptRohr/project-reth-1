extends Control

@export var enabled := true
@export var padding := Vector2(10, 8)
@export var line_width := 4.0
@export var border_color := Color(1.0, 0.92, 0.2, 0.95)
@export var fill_color := Color(1.0, 0.92, 0.2, 0.16)
@export var pulse_speed := 6.0

var _focused: Control = null
var _pulse: float = 0.0
var _focus_stack: Array[Control] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	_update_enabled_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_update_enabled_state()

func _update_enabled_state() -> void:
	if Input.get_connected_joypads().is_empty():
		hide()
	else:
		show()

func push_focus(control: Control) -> void:
	if control == null:
		return
	if is_instance_valid(_focused):
		_focus_stack.append(_focused)
	control.grab_focus()

func pop_focus() -> void:
	while not _focus_stack.is_empty():
		var previous: Control = _focus_stack.pop_back()
		if is_instance_valid(previous) and previous.is_visible_in_tree():
			previous.grab_focus()
			return

func restore_last_focus() -> void:
	pop_focus()

func _process(delta: float) -> void:
	if not enabled:
		return
	if _focused == null or not is_instance_valid(_focused) or not _focused.is_visible_in_tree():
		if visible:
			hide()
		return
	_pulse += delta * pulse_speed
	queue_redraw()

func _on_gui_focus_changed(control: Control) -> void:
	if not enabled:
		return
	if control == null:
		return
	if not (control is Button or control is OptionButton or control is CheckBox or control is HSlider or control is LineEdit or control is TextEdit):
		return
	if not control.is_visible_in_tree():
		return
	_focused = control
	show()
	queue_redraw()

func _draw() -> void:
	if _focused == null or not is_instance_valid(_focused) or not _focused.is_visible_in_tree():
		return
	var rect: Rect2 = _focused.get_global_rect().grow_individual(padding.x, padding.y, padding.x, padding.y)
	var alpha: float = 0.65 + 0.2 * sin(_pulse)
	var draw_border: Color = Color(border_color.r, border_color.g, border_color.b, border_color.a * alpha)
	var draw_fill: Color = Color(fill_color.r, fill_color.g, fill_color.b, fill_color.a * alpha)
	draw_rect(rect, draw_fill, true)
	draw_rect(rect, draw_border, false, line_width)
