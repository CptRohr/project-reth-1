extends Area2D

@export_file("*.tscn") var target_scene
@export var target_spawn := "FromStreet"

var player_inside = false
var can_move = true
var player: Node2D

func _on_body_entered(body):
	print("ENTERED:", body.name)

	if body.name == "Player":
		player = body
		player_inside = true
		print("PLAYER INSIDE")

func _on_body_exited(body):
	if body.name == "Player":
		player = null
		player_inside = false

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		print("TRYING TO CHANGE SCENE")
		player.can_move = false
		await SceneManager.transition_to(target_scene, target_spawn)
