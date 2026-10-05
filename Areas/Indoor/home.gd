#this one is exclusion for a scene that doesn't affected by the time filter
extends CanvasLayer

@export_group("Indoor Camera Override")
@export var override_indoor_camera := false
@export var indoor_zoom_factor := 1.0

@onready var spawn_points = get_node_or_null("SpawnPoints")

func get_indoor_zoom_factor() -> float:
	return indoor_zoom_factor


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
