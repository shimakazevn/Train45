extends Node

@export var target_node: Control
var current_theme: Theme

func _ready() -> void:
	LanguageManager.lang_changed.connect(_lang_changed)
	current_theme = target_node.theme
	#_change_theme()

func _change_theme():
	target_node.theme = LanguageManager.apply_theme(LanguageManager.get_current_locale())

func _lang_changed(_locale: String):
	#_change_theme()
	pass
