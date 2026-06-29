extends AnimationPlayer

@export var current_npc_entitiy: CurrentNpc
@export var reina_dummy: CharacterBody2D
@export var mai_dummy: CharacterBody2D


func _ready() -> void:
	GameEvents.cutscene_play.connect(_on_cutscene_play)
	#Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_cutscene_play(cutscene_name: String):
	for i in self.get_animation_list():
		if i == cutscene_name:
			update_cutscene(cutscene_name)
			break

func update_cutscene(cutscene_name: String):
	self.play(cutscene_name)
	current_npc_entitiy.hide()

##카메라의 위치를 맞추기 위해 현재 동행중인 히로인의 위치도 같이 변경한다
func original_npc_position_sync():
	var current_partner = current_npc_entitiy.current_partner as Npc
	match current_partner.npc_name:
		Constants.NPC_OL:
			current_partner.position = reina_dummy.position
		Constants.NPC_GYARU:
			current_partner.position = mai_dummy.position

###대화창이 끝나면 실행중인 애니메이션이 모두 정지되도록 처리
#func _on_timeline_ended():
	#if self.is_playing():
		#self.stop()
		#current_npc_entitiy.show()
		#var current_partner = current_npc_entitiy.current_partner as Npc
		#match current_partner.npc_name:
			#Constants.NPC_OL:
				#current_partner.position = reina_dummy.position
			#Constants.NPC_GYARU:
				#current_partner.position = mai_dummy.position
