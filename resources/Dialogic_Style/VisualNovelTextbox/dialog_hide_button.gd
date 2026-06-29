extends Button


@onready var dialog_text_panel: PanelContainer = %DialogTextPanel

var hide_button_pressed: bool = false

func _ready() -> void:
	self.hide()
	dialog_text_panel.visibility_changed.connect(_on_textbox_visible_changed.bind(dialog_text_panel))

func _on_pressed() -> void:
	if Dialogic.Text.is_textbox_visible():
		if Dialogic.Animations.is_animating():
			return
		Dialogic.Text.hide_textbox(true)
		hide_button_pressed = true
		if Dialogic.Inputs.auto_skip.enabled:
			Dialogic.Inputs.auto_skip.enabled = false

func _input(event: InputEvent) -> void:
	if GameEvents.get_window_state("safe_stage_h_action"):
		return
	if not Dialogic.Text.is_textbox_visible() and hide_button_pressed and event.is_pressed():
		hide_button_pressed = false
		Dialogic.Inputs.block_input(0.1)
		get_viewport().set_input_as_handled()
		Dialogic.Text.show_textbox(true)
		var speaker_path: String = Dialogic.current_state_info.get('speaker', '')
		if not speaker_path.is_empty():
			var character := load(speaker_path) as DialogicCharacter
			if character:
				Dialogic.Text.update_name_label(character)
	elif event.is_action_pressed("dialogic_hide"):
		_on_pressed()
		get_viewport().set_input_as_handled()

func _on_textbox_visible_changed(target: PanelContainer):
	self.visible = target.visible
	GameEvents.emit_textbox_visible_changed(target.visible)
