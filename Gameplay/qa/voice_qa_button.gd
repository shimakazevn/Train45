extends Button

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var voice_id: String = ""
var char_name: String = ""
var has_file: bool = false
var _section: Node = null

func setup(id: String, p_char_name: String, dialogue: String, path: String, file_exists: bool, section: Node) -> void:
	voice_id = id
	char_name = p_char_name
	has_file = file_exists
	_section = section
	var translated := _get_translated(id, dialogue)
	var prefix := (char_name + ": ") if not char_name.is_empty() else ""
	text = "[%s]  %s%s" % [id, prefix, translated]
	toggle_mode = true

	if file_exists:
		audio_player.stream = load(path)
		toggled.connect(_on_toggled)
		audio_player.finished.connect(_on_finished)
	else:
		disabled = true
		self_modulate = Color(1, 1, 1, 0.4)

func _get_translated(id: String, fallback: String) -> String:
	for prefix: String in ["Text", "Choice"]:
		var key: String = prefix + "/" + id + "/text"
		var t: String = tr(key)
		if t != key:
			return t
	return fallback

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_section.viewer.on_button_played(self)
		audio_player.play()
	else:
		audio_player.stop()

func stop() -> void:
	button_pressed = false
	audio_player.stop()

func play_voice() -> void:
	button_pressed = true
	_section.viewer.on_button_played(self)
	audio_player.play()

func _on_finished() -> void:
	button_pressed = false
	_section.viewer.on_voice_finished(self)
