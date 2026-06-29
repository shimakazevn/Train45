extends Button
class_name TutorialBookListButton

var tutos: Tutos

func _ready() -> void:
	if tutos:
		self.text = tutos.title
