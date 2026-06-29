extends ColorRect

var target_position : Vector2
@onready var particles: GPUParticles2D = $GPUParticles2D

var tween : Tween

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	self.scale = Vector2(0.3, 0.3)
	var offset = size / 2
	tween = create_tween()
	tween.tween_property(self, "position", target_position - offset, 2.0)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	call_deferred("emitting_particle")
	await tween.finished
	particles.emitting = false
	#particles.hide()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 1.0)\
	.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func emitting_particle():
	await get_tree().create_timer(0.2).timeout
	particles.position = Vector2(26, 26)
	particles.emitting = true

func _on_stage_clear():
	self.queue_free()
