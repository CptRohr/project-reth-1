extends CharacterBody2D

@export var speed := 180.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")



func _physics_process(delta):
	var direction := Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("interact"):
		print("INTERACT PRESSED")
	velocity.x = direction * speed
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

	update_facing(direction)

func update_facing(direction):
	if direction != 0:
		$Sprite2D.flip_h = direction < 0
