extends NinePatchRect

var tween : Tween
@onready var white_rect: ColorRect = $ColorRect

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)

	tween = create_tween()
	tween.tween_property(self, "size:x", 1920, 2.0)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	white_rect.show()
	tween = create_tween()
	tween.tween_property(white_rect, "color", Color(1,1,1,0), 1.0)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_stage_clear():
	self.queue_free()
