extends Area2D

##해당 챕터가 아니면 이벤트가 발생하지 않음
@export var chapter: int = 0
##해당 엔피씨와 대화 시작
@export var npc : Npc
## 메인 퀘스트일 때 체크
@export var is_quest:= false
var is_clear := false

@export var quest_component: QuestComponent
@export var quest_screen: CanvasLayer


func _ready() -> void:
	if MetaProgression.get_current_chapter() != chapter:
		if is_quest:
			quest_component.hide()
		monitoring = false
		return
	else:
		if is_quest:
			quest_component.show()
			quest_component.quest_clear.connect(_on_clear)

	quest_screen.show()
	
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)


func _on_body_entered(body: Node2D):
	if not body is Player:
		return

	if is_quest:
		if is_clear:
			GameEvents.emit_player_talk(npc)
		else:
			GameEvents.emit_player_talk(npc, "quest_failed")
	else:
		GameEvents.emit_player_talk(npc)

func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return


func _on_clear():
	is_clear = true

func _on_timeline_started():
	quest_screen.hide()
func _on_timeline_ended():
	quest_screen.show()
