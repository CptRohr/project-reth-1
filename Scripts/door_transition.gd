extends Area2D

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: String = "FromStreet"

var player_inside: bool = false
var transitioning: bool = false
var player: Node2D


func _on_body_entered(body: Node2D) -> void:
	print("ENTERED:", body.name)

	if body.is_in_group("Player") or body.name == "Player":
		player = body
		player_inside = true
		if player.has_method(&"register_interactable"):
			player.register_interactable(self)
		print("PLAYER INSIDE")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		if body.has_method(&"unregister_interactable"):
			body.unregister_interactable(self)
		player = null
		player_inside = false


func _process(_delta):
	if not player_inside or transitioning or not Input.is_action_just_pressed("interact"):
		return

	if target_scene == "":
		push_error("DoorTransition target_scene is empty on %s." % get_path())
		return

	if player == null or not is_instance_valid(player):
		push_error("DoorTransition has no valid player reference on %s." % get_path())
		player_inside = false
		return

	print("TRYING TO CHANGE SCENE")
	transitioning = true
	player.set("can_move", false)
	await SceneManager.transition_to(target_scene, target_spawn)
	transitioning = false
