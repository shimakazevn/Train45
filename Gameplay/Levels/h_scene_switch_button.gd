extends RecollectionButton
class_name RecollectionButtonMini

@onready var h_scene_title_rect: ColorRect = %HSceneTitleRect
@onready var ticket_multiplier_label: Label = %TicketMultiplierLabel

var bonus_ticket_multiplier: int = 0

func ready_override():
	self.focus_entered.connect(_on_focus_changed.bind(true))
	self.focus_exited.connect(_on_focus_changed.bind(false))

func hide_mouse_on_button():
	h_scene_title_rect.hide()

func _on_mouse_entered() -> void:
	if lock_screen.visible == false:
		#h_scene_title_rect.show()
		grab_focus()


func _on_mouse_exited() -> void:
	if lock_screen.visible == false:
		#h_scene_title_rect.hide()
		pass

func set_multiplier():
	if bonus_ticket_multiplier > 0:
		var hearts := ""
		for i in bonus_ticket_multiplier:
			hearts += "♥"
		ticket_multiplier_label.text = hearts
		ticket_multiplier_label.show()
	else:
		ticket_multiplier_label.text = ""
		ticket_multiplier_label.hide()

func get_ticket_multiplier()-> int:
	return bonus_ticket_multiplier

func _on_focus_changed(is_focus: bool):
	if is_focus:
		h_scene_title_rect.show()
	else:
		h_scene_title_rect.hide()
