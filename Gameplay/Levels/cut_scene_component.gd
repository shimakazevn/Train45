extends Node2D
class_name CutSceneComponent


@export var npc_entity: Node2D
@export var cutscene_anim: AnimationPlayer
@onready var dummy_container: Node2D = %DummyContainer

var is_playing:= false

func _ready() -> void:
	GameEvents.cutscene_play.connect(_on_cutscene_play)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	set_cutscene_state(false)

func _on_cutscene_play(cutscene_name: String):
	if not is_playing:
		set_cutscene_state(true)
		
	if cutscene_anim == null:
		push_warning("cutscene이 없습니다.")
		return
	cutscene_anim.play(cutscene_name)

func _on_timeline_ended():
	if is_playing:
		set_cutscene_state(false)

func set_cutscene_state(start: bool):
	if start:
		is_playing = true
		if npc_entity.visible == true:
			npc_entity.hide()
			dummy_container.show()
	else:
		is_playing = false
		if npc_entity.visible == false:
			npc_entity.show()
			dummy_container.hide()
