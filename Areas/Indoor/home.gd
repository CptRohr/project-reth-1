extends Node2D

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
