extends Node

var spawn_id: String = "":
	set(value):
		spawn_id = value
		GameState.set_spawn(spawn_id)


func change_scene(scene_path: String, target_spawn: String) -> bool:
	if scene_path == "":
		push_error("SceneManager.change_scene() received an empty scene path.")
		return false

	if not ResourceLoader.exists(scene_path):
		push_error("SceneManager cannot find target scene: %s" % scene_path)
		return false

	spawn_id = target_spawn
	print("SETTING SPAWN:", spawn_id)
	GameState.set_scene(scene_path)

	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager failed to change scene to %s. Error: %s" % [scene_path, error])
		return false

	return true


func transition_to(scene_path: String, target_spawn: String = "") -> void:
	await Transition.fade_out()

	var changed: bool = change_scene(scene_path, target_spawn)

	if not changed:
		await Transition.fade_in()
		return

	await get_tree().process_frame

	await Transition.fade_in()


func load_saved_game() -> bool:
	if not GameState.load_game():
		return false

	spawn_id = GameState.current_spawn

	if GameState.current_scene != "":
		get_tree().change_scene_to_file(GameState.current_scene)

	return true
