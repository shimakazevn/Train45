extends Node2D

@export var free_action_component: HSceneFreeActionComponent
@onready var kiss_screen: Sprite2D = $KissScreen
@onready var animation_player: AnimationPlayer = $KissScreen/AnimationPlayer

var active_char_anim: AnimationPlayer

enum SubScreenTypes { KISS }
var sub_screen_info: Dictionary = {
	Constants.NPC_OL:{
		"scene2" : [SubScreenTypes.KISS]
	},
	Constants.NPC_GYARU:{
		"scene4" : [SubScreenTypes.KISS],
		"scene22" : [SubScreenTypes.KISS],
		"scene7" : [SubScreenTypes.KISS],
	},
	Constants.NPC_KONIAL:{
	},
	Constants.NPC_PAZUZU:{
	},
	Constants.NPC_BUTLER:{
	}
}

func _ready() -> void:
	free_action_component.anim_info_changed.connect(_on_anim_info_changed)
	free_action_component.free_action_end.connect(_on_free_action_end)
	if self.hide:
		show()

func _on_anim_info_changed(current_npc:int, current_anim:AnimationPlayer, scene_name: String):
	var scene_title: String = scene_name.split("_")[0]
	if sub_screen_info[current_npc].has(scene_title):
		if sub_screen_info[current_npc][scene_title].has(SubScreenTypes.KISS):
			kiss_screen.show()
			match current_npc:
				Constants.NPC_OL:
					animation_player.play("reina")
				Constants.NPC_GYARU:
					animation_player.play("mai")
				Constants.NPC_KONIAL:
					animation_player.play("konial")
	else:
		animation_player.stop()
		kiss_screen.hide()
	
	active_char_anim = current_anim

func _process(_delta: float) -> void:
	if active_char_anim and animation_player.is_playing():
		animation_player.speed_scale = active_char_anim.speed_scale

func _on_free_action_end():
	active_char_anim = null
