extends EventComponent

@export var cutscene_anim: AnimationPlayer
@export var onsen_camera: PhantomCamera2D

func _ready() -> void:
	Dialogic.signal_event.connect(_on_signal_event)
	GameEvents.call_deferred("emit_stage_clear")

func _on_signal_event(arg: String):
	match arg:
		"cutscene_onsen_0":
			onsen_camera.set_priority(100)
		"cutscene_onsen_1":
			cutscene_anim.play("cut_1")
		"cutscene_onsen_2":
			cutscene_anim.play("cut_2")
		"cutscene_onsen_3":
			cutscene_anim.play("cut_3")
		"cutscene_onsen_4":
			cutscene_anim.play("cut_4")
