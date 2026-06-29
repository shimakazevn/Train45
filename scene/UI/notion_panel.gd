## 알림 패널 UI 컴포넌트.
## [br][br]
## 화면에 알림 메시지를 표시하고 10초 후 자동으로 사라진다.
## [method notion_string]으로 텍스트, 아이콘 텍스처, 색상을 설정할 수 있다.
extends Control
class_name NotionBox

## 알림 등장/퇴장 애니메이션을 재생하는 [AnimationPlayer].
@onready var animation_player = $NotionPanel/AnimationPlayer
## 알림 텍스트를 표시하는 [Label].
@export var notion: Label
## 알림 아이콘을 표시하는 [TextureRect].
@export var notion_texture: TextureRect


## 퇴장 애니메이션이 완료되었는지 추적하는 플래그.
var anim_fin := false

## 초기화 시 등장 애니메이션을 재생하고 10초 후 자동 퇴장 타이머를 설정한다.
func _ready():
	animation_player.play("in")
	get_tree().create_timer(10.0).timeout.connect(on_timeout)

## 알림 내용을 설정한다.[br]
## [param notion_str]은 표시할 텍스트, [param texture]는 아이콘,
## [param color]는 아이콘 색조(기본 [code]WHITE[/code])이다.
func notion_string(notion_str: String, texture: CompressedTexture2D = null, color:Color = Color.WHITE):
	notion.text = tr(notion_str)
	if color != Color.WHITE:
		notion_texture.self_modulate = color
	notion_texture.texture = texture

## 타임아웃 시 [method noti_exit]를 호출하여 알림을 퇴장시킨다.
func on_timeout():
	noti_exit()

## 퇴장 애니메이션을 재생하고 완료 시 [member anim_fin]을 [code]true[/code]로 설정한다.
func noti_exit():
	animation_player.play("out")
	await animation_player.animation_finished
	anim_fin = true
