extends Node2D

@onready var spawn_points = get_node_or_null("SpawnPoints")

func _ready():
	GameState.set_scene(scene_file_path)
	print("MAP READY")
	print("Spawn ID:", SceneManager.spawn_id)

	if spawn_points == null:
		print("NO SPAWN POINTS")
		return

	var player = $Player

	for spawn in spawn_points.get_children():
		print("FOUND SPAWN:", spawn.name)

		if spawn.name == SceneManager.spawn_id:
			print("MOVING PLAYER")
			player.global_position = spawn.global_position
