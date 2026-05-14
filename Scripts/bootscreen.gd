extends Control

@export_file("*.tscn") var next_scene := "res://Scene/MainMenu.tscn"
@onready var video: VideoStreamPlayer = $VideoStreamPlayer

var changing_scene := false


func _ready() -> void:
	fit_video_to_window()
	video.finished.connect(_on_video_finished)
	video.play()


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		_go_next()

func _on_video_finished() -> void:
	_go_next()

func _go_next() -> void:
	if changing_scene:
		return

	changing_scene = true
	get_tree().change_scene_to_file(next_scene)


func fit_video_to_window() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	video.set_anchors_preset(Control.PRESET_FULL_RECT)
	video.offset_left = 0
	video.offset_top = 0
	video.offset_right = 0
	video.offset_bottom = 0
	video.expand = true
