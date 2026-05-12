# This is actually The PLayer Script and Movement, but I named it basic_movement because I don't know what else to name it. This script is attached to the Player node and handles movement, animation, and interaction.

extends CharacterBody2D

@export var speed := 70.0
@onready var interaction_area = get_node("InteractionArea")
@onready var anim = $AnimatedSprite2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_move = true
var player_inside = false


func _ready():
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	anim.play("idle")
	if velocity.x != 0:
		anim.play("walk")
	else:
		anim.play("idle")
		
	print(self.name)
	print(get_tree_string_pretty())
	

func _physics_process(delta):
	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("interact"):
		print("INTERACT PRESSED")

	if !can_move:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	velocity.x = direction * speed

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	update_facing(direction)

	# ANIMATION
	if direction != 0:
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "idle":
			anim.play("idle")

func _on_dialogue_started():
	can_move = false

func _on_dialogue_ended():
	can_move = true

func update_facing(direction):
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction < 0


func _on_interaction_area_area_entered(area):
	print("AREA ENTERED:", area.name)

	if area.is_in_group("Player"):
		player_inside = true

func _on_interaction_area_area_exited(area):
	if area.is_in_group("Player"):
		player_inside = false
