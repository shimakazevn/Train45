## [KR] 이상현상 탐지 영역을 관리하는 컴포넌트.
## [KR] [member Player.player_action] 시그널에 반응하여 이상현상 탐지를 수행하며,
## [KR] 탐지 실패 시 플레이어 생명력을 차감한다.
## [EN] Component that manages the anomaly detection area.
## [EN] Performs anomaly detection in response to the [member Player.player_action] signal,
## [EN] and deducts player life on detection failure.
extends Area2D

## [KR] 부모 [Player] 노드 참조
## [EN] Parent [Player] node reference
var player : Player
## [KR] 플레이어가 탐지 영역 안에 있는지 여부
## [EN] Whether the player is within the detection area
var is_player_in_area = false

## [KR] 탐지 시각 효과를 표시하는 [ColorRect]
## [EN] [ColorRect] that displays the detection visual effect
@export var find_effect: ColorRect
## [KR] 탐지 영역의 충돌 셰이프
## [EN] Collision shape of the detection area
@onready var collision_shape: Shape2D = $CollisionShape2D.shape

## [KR] 초기화 시 부모 [Player]를 참조하고 액션 시그널을 연결한다.
## [EN] On initialization, references the parent [Player] and connects the action signal.
func _ready():
	player = get_parent()
	player.player_action.connect(_on_player_action)
	set_detect_size(collision_shape.size)

## [KR] 영역에 진입했을 때 호출된다.
## [KR] [member player.find_lock]이 [code]true[/code]이면 접촉만으로 즉시 탐지 성공 처리한다.
## [EN] Called when entering the area.
## [EN] If [member player.find_lock] is [code]true[/code], immediately triggers detection success on contact.
func _on_area_entered(_area):
	# [KR] 런 스테이지일경우 닿기만 해도 클리어
	# [EN] In run stages, clearing is triggered by contact alone
	if player.find_lock:
		player.find_anomaly.emit()
	is_player_in_area = true

## [KR] 영역에서 벗어났을 때 호출된다.
## [EN] Called when exiting the area.
func _on_area_exited(_area):
	is_player_in_area = false

## [KR] 플레이어 액션 입력 시 탐지를 시도한다.
## [KR] 영역 안이면 탐지 성공, 밖이면 생명력을 1 차감하고
## [KR] 생명력이 0 이하가 되면 [signal Player.find_faild]를 발신한다.
## [EN] Attempts detection on player action input.
## [EN] If inside the area, detection succeeds; if outside, deducts 1 life and
## [EN] emits [signal Player.find_faild] if life drops to 0 or below.
func _on_player_action():
	if is_player_in_area:
		player.find_anomaly.emit()
	else:
		if player.floor_manager.current_level.stage_clear and player.floor_manager.current_level.stage_type != Constants.TYPE_SAFE: ## [KR] 스테이지 클리어 상태일시 리턴 / [EN] Return if stage is in cleared state
			return
		var global_game = player.global_game_manager as GlobalGameManager
		global_game.set_life(-1)
		if global_game.life <= 0:
			print("Detection failed")
			player.find_faild.emit()
		else:
			# [KR] 생명이 남았다 = LIFE_UP(オカボシ0.00001) 장착 중 첫 탐지 실패.
			#      실패해 기회를 1 잃었음을 알리는 효과음을 재생한다.
			# [EN] Life remains = first detection failure while the LIFE_UP item is equipped.
			#      Plays an SFX to signal that a chance was lost on failure.
			player.ui_sound_stream_player.set_stream_play_to_file(UiSoundStreamPlayer.FAIL_TO_FIND_ABNORMALITY)
		print("Remaining detection count : " + str(global_game.life))

## [KR] 탐지 영역 크기를 설정한다.
## [KR] [param size]에 맞게 충돌 셰이프와 시각 효과 크기를 동시에 갱신한다.
## [EN] Sets the detection area size.
## [EN] Simultaneously updates the collision shape and visual effect size to match [param size].
func set_detect_size(size: Vector2):
	collision_shape.size = size
	set_find_effect_size(size)

## [KR] 탐지 시각 효과([member find_effect])의 크기와 위치를 [param shape_size]에 맞춰 조정한다.
## [KR] 위치는 영역 중심을 기준으로 오프셋을 적용한다.
## [EN] Adjusts the size and position of the detection visual effect ([member find_effect]) to match [param shape_size].
## [EN] Position is offset from the area center.
func set_find_effect_size(shape_size: Vector2):
	find_effect.size = shape_size
	var offset_size = shape_size/2
	find_effect.position = position - offset_size
