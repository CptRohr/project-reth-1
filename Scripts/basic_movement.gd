extends CharacterBody2D

@export var speed := 180.0
@onready var interaction_area = get_node("InteractionArea")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_move = true


func _ready():
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
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

func _on_dialogue_started():
	can_move = false

func _on_dialogue_ended():
	can_move = true

func update_facing(direction):
	if direction != 0:
		$Sprite2D.flip_h = direction < 0
