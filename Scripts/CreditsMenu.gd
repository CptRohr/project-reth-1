extends Control

@export_file("*.tscn") var main_menu_scene_path := "res://Scene/MainMenu.tscn"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var back_button: Button = $CanvasLayer/CreditsContainer/Back

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	animation_player.play("creditsscreen")

func _on_back_pressed() -> void:
	back_button.disabled = true
	animation_player.play_backwards("creditsscreen")
	await animation_player.animation_finished
	get_tree().change_scene_to_file(main_menu_scene_path)
