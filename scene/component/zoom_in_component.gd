## [KR] 줌 상태에서 화면(카메라 오프셋)을 이동시키는 컴포넌트.
## [br]free action 중 Ctrl로 팬 모드를 토글하며, 모드가 켜지면 WASD/방향키(move_* 액션)로
## 화면을 상하좌우 이동한다. 줌 배율에 따라 이동 가능 범위가 커지도록 클램프한다(원본 프레임 밖으로 못 나감).
## [br]npc_camera(PhantomCamera2D)는 GROUP 팔로우 모드라 follow_offset이 무시되므로,
## 실제 Camera2D의 offset을 직접 조작한다(호스트가 매 프레임 덮어쓰지 않는 속성).
## [EN] Component that pans the screen (camera offset) while zoomed in.
## [br]Ctrl toggles pan mode during free action; when on, WASD/arrow keys (move_* actions)
## pan the view. Clamped so the view never leaves the original frame (range grows with zoom).
## [br]npc_camera (PhantomCamera2D) uses GROUP follow mode, which ignores follow_offset, so we
## drive the real Camera2D's offset directly (a property the host doesn't overwrite each frame).
extends Control
class_name ZoomInComponent

## [KR] 소속 free action 컴포넌트. 미지정 시 ../.. 경로로 자동 해석한다.
## [EN] Owning free action component. Auto-resolved via ../.. if unset.
@export var free_action_component : HSceneFreeActionComponent

## [KR] 팬 속도(줌 1.0 기준 초당 월드 픽셀). 실제 속도는 줌 배율에 비례해 커진다.
## [EN] Pan speed (world px/sec at zoom 1.0). Actual speed scales with zoom magnification.
@export var pan_speed := 70.0

## [KR] 디버그 로그 출력 여부.
## [EN] Whether to print debug logs.
@export var debug := true


## [KR] 초기화: free action 참조 자동 해석, 시작 시 숨김, 종료 시 복원 연결.
## [EN] Initialization: auto-resolve free action reference, hide on start, connect reset on exit.
func _ready():
	if free_action_component == null:
		free_action_component = get_node_or_null("../..") as HSceneFreeActionComponent
	if free_action_component:
		free_action_component.free_action_end.connect(_on_free_action_end)
	visible = false


## [KR] Ctrl 입력으로 팬 모드를 토글한다. free action 중에만 동작한다.
## [br]팬 모드 중에는 방향 입력(move_*)을 소비하여, switch 버튼 포커스 이동 등
## 다른 UI가 좌우/상하 입력을 가져가지 못하게 막는다.
## [EN] Toggles pan mode on Ctrl input. Only works during free action.
## [br]While pan mode is on, consumes directional input (move_*) so other UI
## (e.g. switch-button focus navigation) can't steal left/right/up/down.
func _input(event: InputEvent) -> void:
	if free_action_component == null or not free_action_component.is_event:
		return
	# [KR] 키보드: Ctrl로 토글
	# [EN] Keyboard: toggle with Ctrl
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_CTRL:
			_set_pan_mode(not free_action_component.is_pan_mode)
			get_viewport().set_input_as_handled()
			return
	# [KR] 패드: L3(왼쪽 스틱 클릭)로 토글. 방향은 D-Pad(move_*)가 담당.
	# [EN] Gamepad: toggle with L3 (left stick click). Direction handled by D-Pad (move_*).
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_LEFT_STICK:
		_set_pan_mode(not free_action_component.is_pan_mode)
		get_viewport().set_input_as_handled()
		return
	# [KR] 팬 모드 중에는 esc로도 팬 모드만 빠져나온다(전체 H 이벤트 종료가 아니라 팬 해제).
	# [br]ZoomInComponent가 free_action_component(루트)보다 _input을 먼저 받으므로, 여기서 소비하면
	# 루트의 esc 핸들러(event_exit)로 넘어가지 않는다.
	# [EN] While in pan mode, ESC also exits pan mode only (turns off panning, not the whole H event).
	# [br]ZoomInComponent receives _input before free_action_component (root), so consuming here
	# prevents the root's esc handler (event_exit) from firing.
	if free_action_component.is_pan_mode and event.is_action_pressed("esc"):
		_set_pan_mode(false)
		get_viewport().set_input_as_handled()
		return

	if free_action_component.is_pan_mode and _is_directional(event):
		get_viewport().set_input_as_handled()


## [KR] 이벤트가 방향 이동(move_*) 입력인지 반환한다. 방향키는 move_*·ui_* 양쪽에 묶여 있어
## 이 이벤트를 소비하면 ui_left/ui_right 등 포커스 이동도 함께 차단된다.
## [EN] Returns whether the event is a directional move_* input. Arrow keys are bound to both
## move_* and ui_*, so consuming this event also blocks ui_left/ui_right focus navigation.
func _is_directional(event: InputEvent) -> bool:
	return event.is_action("move_left") or event.is_action("move_right") \
		or event.is_action("move_up") or event.is_action("move_down") \
		or event.is_action("ui_left") or event.is_action("ui_right") \
		or event.is_action("ui_up") or event.is_action("ui_down")


## [KR] 팬 모드를 설정하고 컴포넌트 표시 상태를 갱신한다.
## [EN] Sets pan mode and updates the component's visibility.
func _set_pan_mode(on: bool) -> void:
	free_action_component.is_pan_mode = on
	visible = on
	if debug:
		var cam2d := _get_camera_2d()
		print("[ZoomIn] 팬모드=%s cam2d=%s zoom=%s offset=%s viewport=%s" % [
			on,
			str(cam2d.name) if cam2d else "null",
			str(cam2d.zoom) if cam2d else "null",
			str(cam2d.offset) if cam2d else "null",
			get_viewport().get_visible_rect().size])


## [KR] 매 프레임 move_* 입력으로 카메라 오프셋을 이동시킨다.
## [br]팬 모드가 아니거나 free action(is_event)이 아니면 동작하지 않는다.
## [EN] Pans the camera offset each frame via move_* input.
## [br]Does nothing unless pan mode is on and free action (is_event) is active.
func _process(delta):
	if free_action_component == null or not free_action_component.is_event:
		return
	if not free_action_component.is_pan_mode:
		return
	var cam2d := _get_camera_2d()
	if cam2d == null:
		if debug:
			print("[ZoomIn] camera_2d 없음 (호스트/활성 카메라 확인)")
		return

	# [KR] WASD/방향키/D-Pad 입력 방향 (move_up=위 → y 음수)
	# [EN] WASD/arrow/D-Pad input direction (move_up=up → negative y)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# [KR] 패드 왼쪽 스틱은 move_*에 없으므로 ui_*로 보완한다(스틱으로도 이동).
	# [EN] The left analog stick isn't in move_*, so supplement with ui_* (so the stick pans too).
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# [KR] 줌 배율에 비례해 팬 속도를 키워 이동 거리를 보정한다.
	# [EN] Scale pan speed by zoom so travel distance compensates for the larger range.
	var zoom: float = max(cam2d.zoom.x, 0.001)
	var prev_offset: Vector2 = cam2d.offset
	var next_offset: Vector2 = prev_offset + dir * pan_speed * zoom * delta

	# [KR] 줌 배율에 따른 최대 오프셋으로 클램프(원본 프레임 밖 이탈 방지)
	# [EN] Clamp to the zoom-based max offset (prevents leaving the original frame)
	var max_offset := _get_max_offset(zoom)
	next_offset.x = clampf(next_offset.x, -max_offset.x, max_offset.x)
	next_offset.y = clampf(next_offset.y, -max_offset.y, max_offset.y)
	cam2d.offset = next_offset

	if debug and dir != Vector2.ZERO:
		print("[ZoomIn] zoom=%.2f dir=%s max=%s prev=%s next=%s applied=%s" % [
			zoom, dir, max_offset, prev_offset, next_offset, cam2d.offset])


## [KR] 줌 배율에서 축별 최대 오프셋을 계산한다.
## [br]보이는 영역 절반 = (뷰포트/2)/zoom 이므로, 원본 프레임 안에 머물려면
## 최대 오프셋 = (뷰포트/2) × (1 − 1/zoom).
## [EN] Computes per-axis max offset from the zoom magnification.
## [br]Visible half-extent = (viewport/2)/zoom, so to stay inside the original frame
## max offset = (viewport/2) × (1 − 1/zoom).
func _get_max_offset(zoom: float) -> Vector2:
	var half := get_viewport().get_visible_rect().size * 0.5
	return half * (1.0 - 1.0 / zoom)


## [KR] 활성 npc 카메라(PhantomCamera2D)가 구동하는 실제 Camera2D를 반환한다. 없으면 null.
## [EN] Returns the real Camera2D driven by the active npc camera (PhantomCamera2D), or null.
func _get_camera_2d() -> Camera2D:
	if free_action_component.npc == null or free_action_component.npc.npc_camera == null:
		return null
	var pcam := free_action_component.npc.npc_camera
	var host = pcam.get_pcam_host_owner()
	if host == null:
		return null
	return host.camera_2d


## [KR] free action 종료 시 팬 모드를 끄고 카메라 오프셋을 0으로 복원한다(다른 상태에 영향 방지).
## [EN] On free action exit, turns off pan mode and resets the camera offset to zero (no leak to other states).
func _on_free_action_end():
	if free_action_component:
		free_action_component.is_pan_mode = false
	visible = false
	var cam2d := _get_camera_2d()
	if cam2d:
		cam2d.offset = Vector2.ZERO
