extends VBoxContainer

@export var slider: XUIBarycentricSlider
@export var values: RichTextLabel = $values

func _ready() -> void:
	slider.weights_changed.connect(_on_weights_changed)

func _on_weights_changed(weights : Dictionary) -> void:
	var text = ""
	for name in weights.keys():
		var value = weights[name]
		var val_s = "%.1f" % value
		text += name + " = " + val_s + "\n"
	
	values.text = text.rstrip("\n")
