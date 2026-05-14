extends CanvasLayer

var root_control: Control
var title_label: Label
var body_label: Label
var continue_button: Button
var active := false
var save_after_school := true


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_summary()


func show_for_current_day(should_save := true) -> void:
	if active:
		return

	active = true
	save_after_school = should_save
	get_tree().paused = true
	title_label.text = "School"
	body_label.text = "You attended school.\nThe day continues after school."
	root_control.visible = true


func hide_summary() -> void:
	active = false
	root_control.visible = false


func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 180)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	body_label = Label.new()
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body_label)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)


func _on_continue_pressed() -> void:
	hide_summary()
	GameState.finish_morning_school()
	if save_after_school:
		GameState.save_game()
	get_tree().paused = false
