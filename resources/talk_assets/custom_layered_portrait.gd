@tool
extends "res://addons/dialogic/Modules/LayeredPortrait/layered_portrait.gd"

var unhighlighted_color := Color.DARK_GRAY
var _prev_z_index := 0

func _ready() -> void:
	if not Engine.is_editor_hint():
		self.modulate = unhighlighted_color


func _highlight() -> void:
	create_tween().tween_property(self, 'modulate', Color.WHITE, 0.15)
	_prev_z_index = DialogicUtil.autoload().Portraits.get_character_info(character).get('z_index', 0)
	DialogicUtil.autoload().Portraits.change_character_z_index(character, 99)


func _unhighlight() -> void:
	create_tween().tween_property(self, 'modulate', unhighlighted_color, 0.15)
	DialogicUtil.autoload().Portraits.change_character_z_index(character, _prev_z_index)
