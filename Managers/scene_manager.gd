extends Node

var spawn_id = "":
	set(value):
		spawn_id = value
		GameState.set_spawn(spawn_id)

func change_scene(scene_path: String, target_spawn: String):
	spawn_id = target_spawn
	print("SETTING SPAWN:", spawn_id)
	GameState.set_scene(scene_path)

	get_tree().change_scene_to_file(scene_path)

func transition_to(scene_path, target_spawn=""):
	await Transition.fade_out()

	change_scene(scene_path, target_spawn)

	await get_tree().process_frame

	await Transition.fade_in()


func load_saved_game() -> bool:
	if not GameState.load_game():
		return false

	spawn_id = GameState.current_spawn

	if GameState.current_scene != "":
		get_tree().change_scene_to_file(GameState.current_scene)

	return true
