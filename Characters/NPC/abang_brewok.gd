extends Node2D

@export var timeline_name := "AbangBrewok"

var player_inside = false

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if !Dialogic.current_timeline:
			Dialogic.start(timeline_name)

func _on_interaction_area_area_entered(area):
	print("AREA ENTERED:", area.name)

	if area.is_in_group("Player"):
		player_inside = true
		print("PLAYER INSIDE")

func _on_interaction_area_area_exited(area):
	if area.is_in_group("Player"):
		player_inside = false