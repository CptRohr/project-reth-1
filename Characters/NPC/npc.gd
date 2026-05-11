extends CharacterBody2D

@export var timeline_name := "test"

var player_inside = false

func _ready():
	pass

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if !Dialogic.current_timeline:
			Dialogic.start(timeline_name)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = true
		print("PLAYER INSIDE")
		print(body.name)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = false
		print("PLAYER LEFT")
