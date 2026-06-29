extends TextureRect

@onready var note_text: TextEdit = %NoteText
@export var pause_menu: PauseMenu

var tween: Tween
var out_position: float = 619.0
var in_position: float = 490.0

const NOTE_FILE_PATH = "user://note.txt"

func _ready() -> void:
	pause_menu.exit_pause_menu.connect(_on_exit_pause_menu)
	position.x = out_position
	tween = create_tween()
	tween.tween_property(self, "position:x", in_position, 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	_load_note()
	note_text.text_changed.connect(_on_text_changed)

func _load_note() -> void:
	if FileAccess.file_exists(NOTE_FILE_PATH):
		var file = FileAccess.open(NOTE_FILE_PATH, FileAccess.READ)
		if file == null:
			push_error("note 파일 열기 실패 (READ): %s" % FileAccess.get_open_error())
			return
		note_text.text = file.get_as_text()

func _on_text_changed() -> void:
	var file = FileAccess.open(NOTE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("note 파일 열기 실패 (WRITE): %s" % FileAccess.get_open_error())
		return
	file.store_string(note_text.text)

func _on_exit_pause_menu():
	tween = create_tween()
	tween.tween_property(self, "position:x", out_position, 0.3).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
