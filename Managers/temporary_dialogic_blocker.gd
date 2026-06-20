class_name TemporaryDialogicBlocker
extends RefCounted

# Temporary Dialogic shutdown while the plugin is broken on the current Godot version.
const OVERLAY_NAME := "TemporaryDialogicBrokenOverlay"
const MESSAGE := "broken"
const DISPLAY_TIME := 1.5


static func show_broken_message(source: Node) -> void:
	if source == null or source.get_tree() == null:
		return

	var root := source.get_tree().root
	var existing := root.get_node_or_null(OVERLAY_NAME)
	if existing:
		existing.queue_free()

	var layer := CanvasLayer.new()
	layer.name = OVERLAY_NAME
	layer.layer = 128
	root.add_child(layer)

	var label := Label.new()
	label.text = MESSAGE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	layer.add_child(label)

	source.get_tree().create_timer(DISPLAY_TIME).timeout.connect(func():
		if is_instance_valid(layer):
			layer.queue_free()
	)
