extends CanvasLayer

@onready var overlay: Control = $Overlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed) == false:
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_visibility()

func push_focus(control: Control) -> void:
	if overlay and overlay.has_method("push_focus"):
		overlay.call("push_focus", control)

func pop_focus() -> void:
	if overlay and overlay.has_method("pop_focus"):
		overlay.call("pop_focus")

func restore_last_focus() -> void:
	if overlay and overlay.has_method("restore_last_focus"):
		overlay.call("restore_last_focus")

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_visibility()

func _update_visibility() -> void:
	if overlay == null:
		return
	overlay.enabled = Input.get_connected_joypads().size() > 0
	if not overlay.enabled:
		overlay.hide()
