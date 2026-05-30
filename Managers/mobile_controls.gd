extends CanvasLayer

const MAIN_MENU_SCENE := "res://Scene/MainMenu.tscn"
const BOOT_SCENE := "res://Scene/BootScene.tscn"
const OPENING_CUTSCENE_SCENE := "res://Areas/Cutscenes/opening_cutscene.tscn"

@export var force_visible: bool = false
@export var show_on_desktop_touchscreen: bool = true

@onready var root_control: Control = $RootControl

var pressed_actions: Dictionary = {}
var dialogue_active: bool = false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	_connect_button("RootControl/MovementRow/LeftButton", "move_left")
	_connect_button("RootControl/MovementRow/RightButton", "move_right")
	_connect_button("RootControl/ActionRow/InteractButton", "interact")
	_connect_button("RootControl/ActionRow/PauseButton", "pause_menu")
	_update_visibility()


func _process(_delta: float) -> void:
	_update_visibility()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_release_all_actions()


func _connect_button(button_path: NodePath, action_name: String) -> void:
	var button: Button = get_node(button_path)
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(_press_action.bind(action_name))
	button.button_up.connect(_release_action.bind(action_name))
	button.visibility_changed.connect(_release_action.bind(action_name))


func _press_action(action_name: String) -> void:
	if not root_control.visible:
		return

	if action_name == "pause_menu":
		PauseMenu.toggle_pause_menu()
		return

	pressed_actions[action_name] = true
	Input.action_press(action_name)


func _release_action(action_name: String) -> void:
	if not pressed_actions.has(action_name):
		return

	pressed_actions.erase(action_name)
	Input.action_release(action_name)


func _release_all_actions() -> void:
	for action_name in pressed_actions.keys():
		Input.action_release(str(action_name))

	pressed_actions.clear()


func _update_visibility() -> void:
	var should_show: bool = force_visible or _has_touch_controls()

	if dialogue_active or _is_non_game_scene():
		should_show = false

	if root_control.visible == should_show:
		return

	root_control.visible = should_show

	if not should_show:
		_release_all_actions()


func _has_touch_controls() -> bool:
	if OS.has_feature("mobile"):
		return true

	return show_on_desktop_touchscreen and DisplayServer.is_touchscreen_available()


func _is_non_game_scene() -> bool:
	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return true

	return [MAIN_MENU_SCENE, BOOT_SCENE, OPENING_CUTSCENE_SCENE].has(current_scene.scene_file_path)


func _on_dialogue_started() -> void:
	dialogue_active = true
	_update_visibility()


func _on_dialogue_ended() -> void:
	dialogue_active = false
	_update_visibility()
