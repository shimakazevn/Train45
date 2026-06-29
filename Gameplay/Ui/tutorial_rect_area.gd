extends Area2D

var mouse_in := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("in")
		get_viewport().set_input_as_handled()

func _on_mouse_entered() -> void:
	mouse_in = true
	print(mouse_in)

func _on_mouse_exited() -> void:
	mouse_in = false
	print(mouse_in)
