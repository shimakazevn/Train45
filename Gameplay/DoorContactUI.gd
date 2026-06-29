extends Area2D
## [KR] 문 접촉 감지 UI를 관리하는 [code]Area2D[/code].
## [EN] [code]Area2D[/code] that manages the door contact detection UI.
## [KR] 플레이어가 문 근처에 접근하면 열차 UI를 표시하고, 벗어나면 숨긴다.
## [EN] Shows the train UI when the player approaches near the door, hides when leaving.

## [KR] 열차 UI 노드 참조
## [EN] Train UI node reference
@onready var train_ui = $TrainUI

## [KR] 플레이어가 문 근처에 있는지 여부
## [EN] Whether the player is near the door
var player_nearby:bool = false

## [KR] [param body]가 영역에 진입했을 때 호출된다.
## [EN] Called when [param body] enters the area.
## [KR] [Player]인 경우에만 [member player_nearby]를 활성화하고 UI를 표시한다.
## [EN] Only activates [member player_nearby] and shows UI if [Player].
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	player_nearby = true
	train_ui.visible = true

## [KR] [param body]가 영역에서 이탈했을 때 호출된다.
## [EN] Called when [param body] exits the area.
## [KR] [Player]인 경우에만 [member player_nearby]를 비활성화하고 UI를 숨긴다.
## [EN] Only deactivates [member player_nearby] and hides UI if [Player].
func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	player_nearby = false
	train_ui.visible = false
	
