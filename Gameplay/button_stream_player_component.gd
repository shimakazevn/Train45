## 버튼의 포커스, 클릭, 표시 이벤트에 대응하여 효과음을 재생하는 컴포넌트.
## [UiSoundStreamPlayer]를 상속하며, 부모 [Button] 노드의 시그널을 자동 연결한다.
extends UiSoundStreamPlayer

## 버튼이 화면에 표시될 때 방출되는 시그널.
signal button_show

## 버튼 표시(준비) 시 재생할 오디오 스트림 목록.
@export var is_ready: Array[AudioStream]
## 버튼 포커스 진입 시 재생할 오디오 스트림 목록.
@export var focus: Array[AudioStream]
## 버튼 클릭 시 재생할 오디오 스트림 목록.
@export var pressed: Array[AudioStream]

## 부모 [Button] 노드 참조.
var owner_button: Button

## 노드 준비 시 부모 [Button]의 시그널을 연결한다. 부모가 [Button]이 아니면 초기화를 중단한다.
func _ready() -> void:
	owner_button = get_parent() as Button
	if owner_button == null:
		return
	
	owner_button.focus_entered.connect(_on_focus_entered)
	owner_button.pressed.connect(_on_pressed)
	self.button_show.connect(_is_button_show)
	
## 버튼 포커스 진입 시 [member focus] 목록에서 효과음을 재생한다.
func _on_focus_entered():
	set_stream_play(focus)

## 버튼 클릭 시 [member pressed] 목록에서 효과음을 재생한다.
func _on_pressed():
	set_stream_play(pressed)
	

## 버튼 표시 시 [member is_ready] 목록에서 효과음을 재생한다.
func _is_button_show():
	set_stream_play(is_ready)
