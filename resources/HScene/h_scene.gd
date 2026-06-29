class_name HScene
extends Sprite2D

const NPC_TYPE_NULL: int = -2
var npc_type: int = NPC_TYPE_NULL
var current_anim: AnimationPlayer

func _ready() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	current_anim = get_child(0) as AnimationPlayer
	current_anim.animation_started.connect(_on_anim_started)

func current_anim_play(play: bool):
	if play:
		current_anim.play()
	else:
		if current_anim.is_playing():
			current_anim.stop()

func _on_anim_started(anim_name: String):
	if npc_type != NPC_TYPE_NULL:
		extra_setting(npc_type, anim_name)

## 특정 h씬들의 추가 설정, 예를 들어 레이어의 순서 등을 조정
func extra_setting(is_npc_type: int, anim_name: String):
	match is_npc_type:
		Constants.NpcTypes.PAZUZU:
			match anim_name:
				"scene1_1", "scene1_2", "scene1_3", "scene1_4":
					get_parent().z_index = -1
				_:
					get_parent().z_index = 0
