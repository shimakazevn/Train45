## [KR] 플레이어 피격 시 화면 비네트 효과를 재생하는 캔버스 레이어.
## [EN] Canvas layer that plays a screen vignette effect when the player is hit.
extends CanvasLayer


## [KR] 노드 준비 시 플레이어 피격 시그널에 콜백을 연결한다.
## [EN] Connects callback to player damaged signal on node ready.
func _ready():
	GameEvents.player_damaged.connect(on_player_damaged)
	
	
## [KR] 플레이어 피격 시 "hit" 애니메이션을 재생하여 화면 가장자리에 비네트 효과를 표시한다.
## [EN] Plays the "hit" animation on player damage to display a vignette effect at screen edges.
func on_player_damaged():
	$AnimationPlayer.play("hit")
