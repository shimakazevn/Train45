## [KR] 소유자 노드에 속도 기반 이동 기능을 부여하는 컴포넌트.
## 가속, 감속, [method CharacterBody2D.move_and_slide] 기반 물리 이동을 처리한다.
## [EN] Component granting velocity-based movement to the owner node.
## Handles acceleration, deceleration, and physics movement via [method CharacterBody2D.move_and_slide].
extends Node

## [KR] 이동 최대 속도 (픽셀/초). [member PlayerData.PLAYER_START_SPEED]로 초기화된다.
## [EN] Maximum movement speed (pixels/sec). Initialized with [member PlayerData.PLAYER_START_SPEED].
var max_speed: float = PlayerData.PLAYER_START_SPEED
## [KR] 가속 계수. 값이 클수록 목표 속도에 빠르게 도달한다.
## [EN] Acceleration factor. Higher values reach target speed faster.
var acceleration: float = PlayerData.PLAYER_START_ACCELATION
## [KR] 현재 이동 속도 벡터.
## [EN] Current movement velocity vector.
var velocity = Vector2.ZERO


## [KR] 플레이어를 향해 가속한다.
## 소유자 또는 플레이어가 유효하지 않으면 조기 반환한다.
## [EN] Accelerates toward the player.
## Returns early if owner or player is invalid.
func accelerate_to_player():
	var owner_node2d = owner as Node2D
	if owner_node2d == null:
		return
		
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
		
	var direction = (player.global_position - owner_node2d.global_position).normalized()
	accelerate_in_direction(direction)
	
	
## [KR] 지정한 방향으로 가속한다.
## [code]1 - exp(-a * dt)[/code] 지수 감쇠 보간을 사용하여 프레임률에 독립적인 부드러운 가속을 구현한다.
## [param direction]: 가속 방향 (정규화된 벡터)
## [EN] Accelerates in the specified direction.
## Uses [code]1 - exp(-a * dt)[/code] exponential decay interpolation for frame-rate independent smooth acceleration.
## [param direction]: acceleration direction (normalized vector)
func accelerate_in_direction(direction: Vector2):
	var desired_velocity = direction * max_speed
	velocity = velocity.lerp(desired_velocity, 1 - exp(-acceleration * get_process_delta_time()))
	

## [KR] [member velocity]를 점진적으로 [code]Vector2.ZERO[/code]로 감속시킨다.
## [EN] Gradually decelerates [member velocity] toward [code]Vector2.ZERO[/code].
func decelerate():
	accelerate_in_direction(Vector2.ZERO)
	

## [KR] [param character_body]에 현재 [member velocity]를 적용하고 [method CharacterBody2D.move_and_slide]를 실행한다.
## 충돌 후 보정된 속도를 다시 [member velocity]에 반영한다.
## [EN] Applies current [member velocity] to [param character_body] and executes [method CharacterBody2D.move_and_slide].
## Reflects the post-collision corrected velocity back to [member velocity].
func move(character_body: CharacterBody2D):
	character_body.velocity = velocity
	character_body.move_and_slide()
	velocity = character_body.velocity
