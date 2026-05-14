extends CanvasLayer

@onready var label := Label.new()
@onready var message_timer := Timer.new()

var message := ""


func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	label.position = Vector2(8, 8)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

	message_timer.one_shot = true
	message_timer.timeout.connect(_on_message_timer_timeout)
	add_child(message_timer)

	GameState.state_changed.connect(_update_text)
	GameState.day_changed.connect(_on_day_changed)
	_update_text()


func _process(_delta):
	_update_text()


func show_message(text: String, duration := 2.0) -> void:
	message = text
	message_timer.start(duration)
	_update_text()


func _update_text() -> void:
	var scene_name := GameState.current_scene.get_file()
	var lines := [
		"FPS: %s" % Engine.get_frames_per_second(),
		"Date: %s" % GameState.get_display_date(),
		"Time: %s" % GameState.get_time_block_label(),
		"Spawn: %s" % _empty_text(GameState.current_spawn),
		"Scene: %s" % _empty_text(scene_name),
	]

	if message != "":
		lines.append(message)

	if not GameState.stats.is_empty():
		lines.append("Stats: %s" % GameState.stats)

	label.text = "\n".join(lines)


func _on_day_changed(new_day) -> void:
	show_message("New day: %s" % GameState.get_display_date())


func _on_message_timer_timeout() -> void:
	message = ""
	_update_text()


func _empty_text(value: String) -> String:
	if value == "":
		return "-"

	return value
