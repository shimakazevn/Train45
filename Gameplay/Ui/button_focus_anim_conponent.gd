extends Node
class_name ButtonFocusAnimComponent

@export var target_button: Button

var tween: Tween
var base_scale: Vector2

func _ready() -> void:
	base_scale = target_button.scale
	target_button.focus_entered.connect(_on_focus_entered)
	target_button.focus_exited.connect(_on_focus_exited)
	target_button.mouse_entered.connect(_on_mouse_entered)
	target_button.mouse_exited.connect(_on_mouse_exited)


func set_animate(to: Vector2):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(target_button, "scale", to, 0.1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_focus_entered() -> void:
	set_animate(base_scale * 1.2)

func _on_focus_exited() -> void:
	set_animate(base_scale)

func _on_mouse_entered() -> void:
	set_animate(base_scale * 1.2)

func _on_mouse_exited() -> void:
	if target_button.has_focus():
		return
	set_animate(base_scale)
