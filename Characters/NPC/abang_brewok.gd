extends Node2D

@export var timeline_name := "AbangBrewok"
@export var after_met_timeline := "AbangBrewok_AfterMet"
@export var later_day_timeline := "AbangBrewok_LaterDay"
@export var timeline_rules: Array[Dictionary] = []
@export var met_flag := "met_abang_brewok"
@export var met_day_flag := "met_abang_brewok_day"

var player_inside = false

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if !Dialogic.current_timeline:
			var chosen_timeline := get_dialogue_timeline()
			Dialogic.start(chosen_timeline)

			if not GameState.get_flag(met_flag, false):
				GameState.set_flag(met_flag, true)
				GameState.set_flag(met_day_flag, GameState.day)
			

func _on_interaction_area_area_entered(area):
	print("AREA ENTERED:", area.name)

	if area.is_in_group("Player"):
		player_inside = true
		print("PLAYER INSIDE")

func _on_interaction_area_area_exited(area):
	if area.is_in_group("Player"):
		player_inside = false


func get_dialogue_timeline() -> String:
	var ruled_timeline := EventManager.choose_timeline("", timeline_rules)

	if ruled_timeline != "":
		return ruled_timeline

	if not GameState.get_flag(met_flag, false):
		return timeline_name

	var met_day := int(GameState.get_flag(met_day_flag, GameState.day))

	if GameState.day > met_day:
		return later_day_timeline

	return after_met_timeline
