extends EventComponent

@export var talk1_area : Area2D
@export var pazuzu_cam : PhantomCamera2D
@export var pazuzu : Npc
@onready var event_cut_scene: AnimationPlayer = $EventCutScene

func _ready() -> void:
	pazuzu.call_deferred("anim_change", "hang")
	GameEvents.quest_process.connect(_on_quest_process)

func _on_quest_process(quest_str: String):
	match quest_str:
		"chapter3_talk1":
			talk1_area.monitoring = false
		"pazuzu_look":
			pazuzu_cam.set_priority(100)
		"pazuzu_bind":
			event_cut_scene.stop()
		"pazuzu_exit":
			pazuzu_exit()
func _on_talk_1_area_body_entered(_body: Node2D) -> void:
	dialog_start("chapter3_talk")

func _on_talk_2_area_body_entered(_body: Node2D) -> void:
	dialog_start("chapter3_talk2")

func pazuzu_exit():
	var tween = get_tree().create_tween()
	tween.tween_property(pazuzu, "position:x", 500, 4.0).set_trans(Tween.TRANS_QUART)
