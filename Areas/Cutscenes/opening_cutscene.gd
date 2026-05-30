extends "res://Managers/cutscene_director.gd"

@export var reference_size: Vector2 = Vector2(1280, 720)

@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World
@onready var forest: Node2D = $World/Forest
@onready var cabin_exterior: Node2D = $World/CabinExterior
@onready var cabin_interior: Node2D = $World/CabinInterior
@onready var loft: Node2D = $World/Loft
@onready var escape_path: Node2D = $World/EscapePath
@onready var rain_lines: Node2D = $World/RainLines


func _on_director_ready() -> void:
	get_viewport().size_changed.connect(_fit_to_viewport)
	reset_opening_stage()
	_fit_to_viewport()


func reset_opening_stage() -> void:
	camera.make_current()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	world.position = Vector2.ZERO
	$World/Girl.position = Vector2(-520, 195)
	$World/Girl.visible = true
	$World/SuitedPeople.visible = false
	$World/BlackCar.visible = false
	phone_panel.visible = false
	black_screen.visible = true
	black_screen.color = Color.BLACK
	_set_location_node(forest)
	_fit_to_viewport()


func show_location(location_name: String) -> void:
	var active_location := forest

	match location_name:
		"forest":
			active_location = forest
		"cabin_exterior":
			active_location = cabin_exterior
		"cabin_interior":
			active_location = cabin_interior
		"loft":
			active_location = loft
		"escape_path":
			active_location = escape_path
		_:
			push_warning("Unknown opening location: %s" % location_name)

	_set_location_node(active_location)


func _set_location_node(active_location: Node2D) -> void:
	for location in [forest, cabin_exterior, cabin_interior, loft, escape_path]:
		location.visible = location == active_location

	rain_lines.visible = true
	_fit_to_viewport()


func _fit_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale_factor: float = maxf(viewport_size.x / reference_size.x, viewport_size.y / reference_size.y)
	world.scale = Vector2.ONE * scale_factor
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	_resize_backdrops(viewport_size / scale_factor)


func _resize_backdrops(visible_size: Vector2) -> void:
	var half_size := visible_size * 0.5 + Vector2(80, 80)
	var ground_y: float = minf(205.0, half_size.y - 70.0)

	_set_rect_polygon($World/Forest/Sky, -half_size.x, -half_size.y, half_size.x, ground_y)
	_set_rect_polygon($World/Forest/Ground, -half_size.x, ground_y, half_size.x, half_size.y)
	_set_rect_polygon($World/CabinExterior/CabinSky, -half_size.x, -half_size.y, half_size.x, ground_y)
	_set_rect_polygon($World/CabinExterior/CabinGround, -half_size.x, ground_y, half_size.x, half_size.y)
	_set_rect_polygon($World/CabinInterior/InteriorWall, -half_size.x, -half_size.y, half_size.x, half_size.y)
	_set_rect_polygon($World/CabinInterior/InteriorFloor, -half_size.x, ground_y - 15.0, half_size.x, half_size.y)
	_set_rect_polygon($World/Loft/LoftWall, -half_size.x, -half_size.y, half_size.x, half_size.y)
	_set_rect_polygon($World/EscapePath/PathSky, -half_size.x, -half_size.y, half_size.x, ground_y)
	_set_rect_polygon($World/EscapePath/PathGround, -half_size.x, ground_y, half_size.x, half_size.y)


func _set_rect_polygon(node: Polygon2D, left: float, top: float, right: float, bottom: float) -> void:
	node.polygon = PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
