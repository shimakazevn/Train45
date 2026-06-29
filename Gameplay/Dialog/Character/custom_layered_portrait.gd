@tool
extends "res://addons/dialogic/Modules/LayeredPortrait/layered_portrait.gd"

@export var npc_name: String
var unhighlighted_color := Color.DARK_GRAY
var _prev_z_index := 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Dialogic.signal_event.connect(_on_signal_event)
	self.modulate = unhighlighted_color


func _highlight() -> void:
	create_tween().tween_property(self, 'modulate', Color.WHITE, 0.15)
	_prev_z_index = DialogicUtil.autoload().Portraits.get_character_info(character).get('z_index', 0)
	DialogicUtil.autoload().Portraits.change_character_z_index(character, 99)


func _unhighlight() -> void:
	create_tween().tween_property(self, 'modulate', unhighlighted_color, 0.15)
	DialogicUtil.autoload().Portraits.change_character_z_index(character, _prev_z_index)

func _on_signal_event(arg: String):
	match arg:
		"highlight_reina":
			if npc_name == "reina":
				_highlight()
		"highlight_mai":
			if npc_name == "mai":
				_highlight()
		"highlight_konial":
			if npc_name == "konial":
				_highlight()
		"highlight_pazuzu":
			if npc_name == "pazuzu":
				_highlight()
		"highlight_butler":
			if npc_name == "butler":
				_highlight()
