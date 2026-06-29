## 고드름 장애물 세트.
## [br][br]
## 경고 애니메이션을 재생한 뒤 고드름이 떨어지는 장애물 오브젝트.
## 스테이지 실패 시 [member hit_monitaring]을 비활성화하여 피해 판정을 중단한다.
extends Node2D

## 고드름 낙하 전 경고 애니메이션을 재생하는 [AnimationPlayer].
@onready var warning_player = $Icicle_Warning/WarningPlayer
## 부모 플레이그라운드 노드 참조 (스테이지 실패 상태 확인용).
var play_ground : Node2D
## 피격 판정 활성화 여부. 스테이지 실패 시 [code]false[/code]가 된다.
var hit_monitaring = true
## 초기화 시 경고 애니메이션을 재생하고 부모 노드를 캐싱한다.
func _ready():
	warning_player.play("ready")
	play_ground = get_parent()

## 매 프레임 스테이지 실패 여부를 확인하여 피격 판정을 비활성화한다.
func _process(_delta):
	if play_ground.stage_failed == true:
		hit_monitaring = false
