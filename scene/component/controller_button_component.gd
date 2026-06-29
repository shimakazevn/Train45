extends TextureRect
class_name PadUiIcon

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		show()
	elif event is InputEventJoypadMotion:
		if (event as InputEventJoypadMotion).axis_value > 0.2:
			show()
	elif event is InputEventKey or event is InputEventMouseButton:
		hide()
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative != Vector2.ZERO:
		hide()
