## [KR] 카메라 흔들림(셰이크) 효과를 관리하는 매니저.
## [EN] Manager that handles camera shake effects.
## [KR] [signal GameEvents.camera_shake] 및 [signal GameEvents.camera_shake_time] 시그널을 수신하여
## [EN] Receives [signal GameEvents.camera_shake] and [signal GameEvents.camera_shake_time] signals
## [KR] 활성 [PhantomCamera2D]에 랜덤 오프셋을 적용한다.
## [EN] and applies random offset to the active [PhantomCamera2D].
extends Node

## [KR] [PhantomCameraHost] 참조 — 현재 활성 카메라를 조회하는 데 사용
## [EN] [PhantomCameraHost] reference — used to query the currently active camera
@export var camera_host : PhantomCameraHost
## [KR] 현재 활성 상태인 [PhantomCamera2D] 노드
## [EN] Currently active [PhantomCamera2D] node
var current_camera : PhantomCamera2D
## [KR] 매 프레임 적용되는 흔들림 오프셋 벡터
## [EN] Shake offset vector applied every frame
var shake_value := Vector2.ZERO
## [KR] 흔들림 강도 (픽셀 단위)
## [EN] Shake intensity (in pixels)
var magnitude := 3.0

## [KR] 현재 흔들림이 활성 상태인지 여부
## [EN] Whether shaking is currently active
var is_shaking := false

func _ready() -> void:
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	GameEvents.camera_shake.connect(cam_shake)
	GameEvents.camera_shake_time.connect(cam_shake_time)
	current_camera = camera_host._active_pcam_2d
	
## [KR] 매 프레임 활성 카메라가 변경되었는지 확인하고,
## [EN] Checks every frame whether the active camera has changed,
## [KR] 흔들림이 활성이면 랜덤 오프셋을 카메라 위치에 적용한다.
## [EN] and applies random offset to camera position if shaking is active.
func _process(_delta: float) -> void:
	if current_camera != camera_host._active_pcam_2d:
		current_camera = camera_host._active_pcam_2d
		is_shaking = false

	if not is_shaking:
		return
	
	shake_value = Vector2(randf_range(-1,1), randf_range(-1,1)) * magnitude
	current_camera.global_position += shake_value

## [KR] 카메라 흔들림 상태를 [param state]로 설정한다.
## [EN] Sets the camera shake state to [param state].
func cam_shake(state: bool = false):
	is_shaking = state

## [KR] [param duration]초 동안 카메라를 흔든 뒤 자동으로 중지한다.
## [EN] Shakes the camera for [param duration] seconds then automatically stops.
func cam_shake_time(duration: float):
	is_shaking = true
	await get_tree().create_timer(duration).timeout
	is_shaking = false

## [KR] 다이얼로그 타임라인 종료 시 흔들림을 중지한다.
## [EN] Stops shaking when dialogue timeline ends.
func _on_timeline_ended():
	cam_shake(false)
