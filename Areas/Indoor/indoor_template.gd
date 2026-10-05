# Indoor Area Script Template
# Attach this script to the root node of any indoor scene under res://Areas/Indoor/

extends Node2D

@export_group("Indoor Camera Override")
@export var override_indoor_camera := false
@export_range(0.1, 4.0, 0.05) var indoor_zoom_factor := 1.25

@onready var spawn_points = get_node_or_null("SpawnPoints")

func _ready():
	GameState.set_scene(scene_file_path)

	if spawn_points == null:
		print("SpawnPoints node missing!")
		return

	var player = $Player

	for spawn in spawn_points.get_children():
		if spawn.name == SceneManager.spawn_id:
			player.global_position = spawn.global_position
			return

	print("Spawn point not found:", SceneManager.spawn_id)

func get_indoor_zoom_factor() -> float:
	return indoor_zoom_factor
