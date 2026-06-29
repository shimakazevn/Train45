extends Node2D

@export var ghost_component: GhostHAnomaly
var is_droped: bool = false
var rot_tween: Tween

func _ready() -> void:
	ghost_component.start_h.connect(_on_start_h)
	set_rot()
	pass

func _on_player_detect_area_body_entered(body: Node2D) -> void:
	if body is Player and not is_droped:
		set_drop()

func set_drop():
	is_droped = true
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "position:y", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

func set_rot():
	rot_tween = create_tween()
	rot_tween.set_loops() # 무한 반복
	rot_tween.tween_property(self, "rotation_degrees", 3, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	rot_tween.tween_property(self, "rotation_degrees", -3, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

##h액션을 시작하면 흔들림을 멈춘다
func _on_start_h():
	rot_tween.kill()
	self.rotation_degrees = 0.0
