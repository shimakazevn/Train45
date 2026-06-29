extends ColorRect
class_name ChapterAnomalyIcon

var tween: Tween

enum State {UNFIND, FIND, NEW}
var is_state: State = State.UNFIND

@onready var ui_sound: UiSoundStreamPlayer = %UiSoundStreamPlayer

func _ready() -> void:
	pass

func set_state(target_state: State) -> void:
	match target_state:
		State.UNFIND:
			color = Color.WEB_GRAY
			ui_sound.set_stream_play_to_file(UiSoundStreamPlayer.ABNORMALITY_NOT_FOUND)
		State.FIND:
			color = Color.WHITE
			ui_sound.set_stream_play_to_file(UiSoundStreamPlayer.ABNORMALITY_FOUND)
		State.NEW:
			color = Color.DEEP_SKY_BLUE
			ui_sound.set_stream_play_to_file(UiSoundStreamPlayer.ABNORMALITY_NEW)

	is_state = target_state
