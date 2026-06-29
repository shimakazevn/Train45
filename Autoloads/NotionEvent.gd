## [KR] 게임 내 알림(노션) 메시지를 중앙에서 발행하는 오토로드 싱글톤.
##
## [EN] Central autoload singleton for publishing in-game notification (Notion) messages.
##
## [KR] UI의 [code]NotiManager[/code]가 [signal notion_call] 시그널을 구독하여 알림을 표시한다.
## [EN] The UI's [code]NotiManager[/code] subscribes to the [signal notion_call] signal to display notifications.
extends Node

## [KR] 알림 요청 시 발생하는 시그널.
## [param str]은 표시할 메시지 텍스트, [param texture]는 함께 표시할 아이콘 텍스처이다.
## [EN] Signal emitted when a notification is requested.
## [param str] is the message text to display, [param texture] is the icon texture to display alongside.
signal notion_call(str: String, texture: CompressedTexture2D)

## [KR] 알림 메시지를 발행한다.
##
## [EN] Publishes a notification message.
##
## [KR] [param _str]은 표시할 텍스트(번역 키 또는 직접 문자열).
## [param texture]는 알림 옆에 표시할 아이콘이며, 없으면 null.
## [param color]는 텍스트 색상이며, 기본값은 흰색이다.
## [EN] [param _str] is the text to display (translation key or direct string).
## [param texture] is the icon to display next to the notification; null if none.
## [param color] is the text color; defaults to white.
func notion(_str: String, texture: CompressedTexture2D = null, color: Color = Color.WHITE):
	notion_call.emit(_str, texture, color)
