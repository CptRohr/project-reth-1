extends Control
class_name PauseMenuClock

@export var hour_hand_path: NodePath
@export var minute_hand_path: NodePath
@export var selector_hand_path: NodePath

@onready var hour_hand: Control = get_node(hour_hand_path)
@onready var minute_hand: Control = get_node(minute_hand_path)
@onready var selector_hand: Control = get_node(selector_hand_path)

var _hour_angle: float = 0.0
var _minute_angle: float = 0.0
var _selector_angle: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_hands()

func set_hour_angle(value: float) -> void:
	_hour_angle = value
	_update_hands()

func set_minute_angle(value: float) -> void:
	_minute_angle = value
	_update_hands()

func set_selector_angle(value: float) -> void:
	_selector_angle = value
	_update_hands()

func _update_hands() -> void:
	if is_instance_valid(hour_hand):
		hour_hand.rotation = _hour_angle
	if is_instance_valid(minute_hand):
		minute_hand.rotation = _minute_angle
	if is_instance_valid(selector_hand):
		selector_hand.rotation = _selector_angle
