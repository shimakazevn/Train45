extends Node

var target_button: Button
var base_size: float
var tween : Tween

func _ready() -> void:
	target_button = get_parent()
	target_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	target_button.focus_entered.connect(_on_focus_entered)
	target_button.focus_exited.connect(_on_focus_exited)
	base_size = target_button.custom_minimum_size.x
	GameEvents.textbox_visible_changed.connect(_on_textbox_visible_changed)



func _on_focus_entered():
	tween = create_tween()
	tween.tween_property(target_button, "custom_minimum_size:x", base_size + 40, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
func _on_focus_exited():
	tween = create_tween()
	tween.tween_property(target_button, "custom_minimum_size:x", base_size, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

### 대화창 숨기기 버튼 눌렀을때 선택지도 투명으로
func _on_textbox_visible_changed(vis: bool):
	if target_button.visible:
		tween = create_tween()
		var target_color: Color
		if vis:
			target_color = Color.WHITE
		else:
			target_color = Color.TRANSPARENT
		tween.tween_property(target_button, "modulate", target_color, 0.4).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
