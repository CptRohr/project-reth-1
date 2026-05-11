extends Node

var spawn_id = ""

func change_scene(scene_path: String, target_spawn: String):
	spawn_id = target_spawn
	print("SETTING SPAWN:", spawn_id)

	get_tree().change_scene_to_file(scene_path)
