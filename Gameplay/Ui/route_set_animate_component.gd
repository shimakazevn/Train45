extends Node

@export var is_owner : RouteSlot

var tween: Tween

func _ready() -> void:
	var current_scale : Vector2 = is_owner.scale
	tween = create_tween()
	tween.tween_property(is_owner, "scale", current_scale,0.2).from(Vector2.ZERO).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
