# This is actually The PLayer Script and Movement, but I named it basic_movement because I don't know what else to name it. This script is attached to the Player node and handles movement, animation, and interaction.

extends CharacterBody2D

@export var speed := 70.0
@onready var interaction_area = get_node("InteractionArea")
@onready var anim = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

@export_group("Dialogue Camera")
@export var dialogue_zoom_enabled := true
@export var dialogue_zoom_factor := 1.25
@export var dialogue_zoom_duration := 0.5
@export var dialogue_camera_blend := 0.5
@export var dialogue_camera_offset := Vector2(0, 0)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_move = true:
	set(value):
		can_move = value
		if not can_move and is_node_ready():
			play_animation("idle")
var player_inside = false

var default_zoom := Vector2(2.75, 2.75)
var active_dialogue_npc: Node2D = null
var camera_tween: Tween = null
var camera_position_smoothing_enabled := false
var camera_rotation_smoothing_enabled := false


func _ready():
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	play_animation("idle")

	print(self.name)
	print(get_tree_string_pretty())
	print(Transition)

	if camera:
		default_zoom = camera.zoom
		camera_position_smoothing_enabled = camera.position_smoothing_enabled
		camera_rotation_smoothing_enabled = camera.rotation_smoothing_enabled

func _physics_process(delta):
	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("interact"):
		print("INTERACT PRESSED")

	if !can_move:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		play_animation("idle")
		return

	velocity.x = direction * speed

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	update_facing(direction)

	# ANIMATION
	if direction != 0:
		play_animation("walk")
	else:
		play_animation("idle")

func _on_dialogue_started():
	can_move = false

func _on_dialogue_ended():
	can_move = true
	if active_dialogue_npc != null:
		_reset_camera()
	active_dialogue_npc = null

func start_dialogue_with(npc: Node2D) -> void:
	active_dialogue_npc = npc
	if dialogue_zoom_enabled:
		_zoom_camera_to_npc(npc)

func _zoom_camera_to_npc(npc: Node2D) -> void:
	if not camera:
		print("[CAMERA DEBUG] Camera is null!")
		return
	
	if camera_tween:
		camera_tween.kill()
		
	var zoom_factor: float = dialogue_zoom_factor
	var blend: float = dialogue_camera_blend
	var offset: Vector2 = dialogue_camera_offset
	
	var npc_has_override = npc.get("override_dialogue_camera") == true
	if npc_has_override:
		zoom_factor = npc.get("dialogue_zoom_factor") as float
		blend = npc.get("dialogue_camera_blend") as float
		offset = npc.get("dialogue_camera_offset") as Vector2
	else:
		# Check if the user set values on the NPC but forgot to turn on override_dialogue_camera
		var npc_offset = npc.get("dialogue_camera_offset")
		var npc_zoom = npc.get("dialogue_zoom_factor")
		var npc_blend = npc.get("dialogue_camera_blend")
		if (npc_offset != null and npc_offset != Vector2.ZERO) or (npc_zoom != null and npc_zoom != 1.25) or (npc_blend != null and npc_blend != 0.5):
			print("[CAMERA WARNING] NPC has custom settings (Offset: %s, Zoom: %s, Blend: %s), but 'override_dialogue_camera' is FALSE! These NPC settings are ignored." % [npc_offset, npc_zoom, npc_blend])

	var target_zoom: Vector2 = default_zoom * zoom_factor
	var target_global_pos: Vector2 = global_position.lerp(npc.global_position, blend)
	var target_local_pos: Vector2 = to_local(target_global_pos) + offset
	
	print("[CAMERA DEBUG] Dialogue zoom started with NPC: %s" % npc.name)
	print("               Player Pos: %s, NPC Pos: %s" % [global_position, npc.global_position])
	print("               Target Zoom: %s (factor: %f)" % [target_zoom, zoom_factor])
	print("               Target Local Pos: %s (offset: %s, blend: %f)" % [target_local_pos, offset, blend])

	# Tweening a smoothed camera can cause the zoom-in to feel late or stuttery.
	# Disable smoothing while the dialogue camera tween is active, then restore it on reset.
	camera.position_smoothing_enabled = false
	camera.rotation_smoothing_enabled = false

	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(camera, "position", target_local_pos, dialogue_zoom_duration)
	camera_tween.tween_property(camera, "zoom", target_zoom, dialogue_zoom_duration)

func _reset_camera() -> void:
	if not camera:
		return
		
	if camera_tween:
		camera_tween.kill()
		
	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(camera, "position", Vector2.ZERO, dialogue_zoom_duration)
	camera_tween.tween_property(camera, "zoom", default_zoom, dialogue_zoom_duration)
	camera_tween.finished.connect(_restore_camera_smoothing)


func _restore_camera_smoothing() -> void:
	if not camera:
		return

	camera.position_smoothing_enabled = camera_position_smoothing_enabled
	camera.rotation_smoothing_enabled = camera_rotation_smoothing_enabled

func update_facing(direction):
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction < 0

func play_animation(animation_name: String):
	if anim.animation != animation_name:
		anim.play(animation_name)


func _on_interaction_area_area_entered(area):
	print("AREA ENTERED:", area.name)

	if area.is_in_group("Player"):
		player_inside = true

func _on_interaction_area_area_exited(area):
	if area.is_in_group("Player"):
		player_inside = false
