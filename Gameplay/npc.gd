extends CharacterBody2D
class_name Npc
## [KR] NPC 기본 클래스.
## [EN] NPC base class.
## [KR] 전차 내 모든 NPC의 공통 동작(호감도, 애니메이션, 카메라, 위치)을 담당한다.
## [EN] Handles common behaviors (affection, animation, camera, position) for all NPCs in the train.
## [KR] [PartnerManager]를 통해 인스턴스화되며, [signal love_level_up_event] 등으로 상위 시스템과 통신한다.
## [EN] Instantiated via [PartnerManager] and communicates with upper systems through [signal love_level_up_event], etc.


## [KR] 호감도 레벨업 시 발생. [param npc_type]은 NPC 식별 인덱스.
## [EN] Emitted on affection level-up. [param npc_type] is the NPC identification index.
signal love_level_up_event(npc_type: int)
## [KR] 경험치가 목표치에 도달하면 발생. [param npc_type]은 NPC 식별 인덱스.
## [EN] Emitted when experience reaches the target. [param npc_type] is the NPC identification index.
signal exp_max(npc_type: int)

## [KR] 현재 층([code]FloorManager[/code]) 참조. 스테이지 정보 접근에 사용.
## [EN] Reference to the current floor ([code]FloorManager[/code]). Used for accessing stage info.
var floor_manager : FloorManager
## [KR] H씬 데이터 리소스 배열. [method _ready]에서 경로 기반으로 로드.
## [EN] H-scene data resource array. Loaded by path in [method _ready].
var h_scene_data_array : Array = []

## [KR] [member stage_state]가 [code]NONE[/code]일 때만 대화 가능.
## [EN] Dialogue is only possible when [member stage_state] is [code]NONE[/code].
## [KR] [code]NPC_HIDE[/code] 상태에서는 플레이어 상호작용을 차단한다.
## [EN] Player interaction is blocked in [code]NPC_HIDE[/code] state.
enum StageState {NONE, NPC_HIDE}
var stage_state = StageState.NONE


## [KR] NPC 이름(타입). [code]Constants[/code]의 NPC 인덱스에 대응.
## [EN] NPC name (type). Corresponds to NPC index in [code]Constants[/code].
@export_enum("ol","gyaru","konial","pazuzu","butler") var npc_name
## [KR] NPC 기본 스프라이트. 좌우 반전([method set_flip])에 사용.
## [EN] NPC base sprite. Used for horizontal flip ([method set_flip]).
@export var npc_sprite : Sprite2D
## [KR] 서브 애니메이션(H씬 일반) 컨테이너 노드.
## [EN] Sub-animation (normal H-scene) container node.
@onready var sub_anim_container: Node2D = $SubAnimContainer
## [KR] 현재 재생 중인 일반 H씬 인스턴스.
## [EN] Currently playing normal H-scene instance.
var npc_sub_scene : HScene
## [KR] 현재 재생 중인 풀스크린 H씬 인스턴스.
## [EN] Currently playing fullscreen H-scene instance.
var npc_sub_full_scene : NpcFullScene
## [KR] 풀스크린 H씬 전용 캔버스.
## [EN] Canvas dedicated to fullscreen H-scenes.
@onready var sub_full_scene_canvas := $SubFullSceneCanvas

## [KR] NPC 전용 [PhantomCamera2D]. 대화·이벤트 시 우선순위를 조절.
## [EN] NPC-dedicated [PhantomCamera2D]. Adjusts priority during dialogue and events.
@export var npc_camera : PhantomCamera2D
## [KR] 카메라 기준 위치 Area2D. 오프셋 적용 후 복원에 사용.
## [EN] Camera reference position Area2D. Used for restoring after offset application.
@onready var camera_position: Area2D = $CameraPosition
## [KR] 카메라 위치 초기값. [method set_base_camera_position]에서 복원용으로 사용.
## [EN] Initial camera position value. Used for restoration in [method set_base_camera_position].
var base_camera_position: Vector2

## [KR] NPC 머리 위 말풍선 UI.
## [EN] Speech bubble UI above the NPC's head.
@export var text_bubble: TalkBubble
## [KR] NPC 메인 애니메이션 플레이어.
## [EN] NPC main animation player.
@onready var animation_player : AnimationPlayer = $AnimationPlayer
## [KR] H씬 자유 행동 컴포넌트. 씬 모드 전환 담당.
## [EN] H-scene free action component. Handles scene mode transitions.
@onready var free_action_component :HSceneFreeActionComponent = $FreeActionComponent
## [KR] 이벤트 위치 관리 컴포넌트. 탐색 위치·기본 위치 저장.
## [EN] Event position management component. Stores search and base positions.
@onready var event_position_component = $EventPositionComponent
## [KR] 서브 H이벤트 컴포넌트.
## [EN] Sub H-event component.
@export var sub_event_component: SubHEventComponent

## [KR] 현재 호감도 레벨 (0부터 시작).
## [EN] Current affection level (starts from 0).
var love_level := 0
## [KR] 다음 레벨업에 필요한 목표 경험치.
## [EN] Target experience required for the next level-up.
var target_love_exp := 100
## [KR] 현재 누적 경험치.
## [EN] Current accumulated experience.
var love_exp := 0
## [KR] 정념(에로) 게이지 값.
## [EN] Desire (ero) gauge value.
var ero_gage := 0
## [KR] 누적 스택 티켓 수.
## [EN] Accumulated stack ticket count.
var stack_ticket := 0
## [KR] 해금된 이벤트 키 목록.
## [EN] List of unlocked event keys.
var unlock_event :Array[String] = []
## [KR] 남은 탐색(찾기) 횟수.
## [EN] Remaining search (find) count.
@export var find_count := 0
## [KR] true이면 씬 트리에 추가되지만 시그널 연결을 건너뛴다 (PartnerManager 데이터 전용 인스턴스).
## [EN] When true, node enters the tree but skips signal connections (data-only instance for PartnerManager).
var data_only := false


## [KR] 노드 초기화. 게임 이벤트·Dialogic 시그널을 연결하고 초기 데이터를 로드한다.
## [EN] Node initialization. Connects game event and Dialogic signals and loads initial data.
func _ready():
	if data_only:
		return
	GameEvents.npc_position_change.connect(_on_npc_position_change)
	GameEvents.anim_change_emit.connect(anim_change)
	GameEvents.anim_change_this_npc.connect(anim_change_this_npc)
	GameEvents.position_change.connect(on_position_change)
	GameEvents.npc_flip.connect(_on_npc_flip)
	GameEvents.camera_order_change.connect(_on_camera_order_change)
	GameEvents.set_camera_base_position.connect(set_base_camera_position)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	base_camera_position = camera_position.position
	h_scene_data_array = TrainUtil.get_res_from_path(HSceneData.H_SCENE_DATA_PATH)
	
	floor_manager = get_tree().get_first_node_in_group("floormanager")


## [KR] 플레이어 접근 여부에 따라 말풍선을 표시하거나 숨긴다.
## [EN] Shows or hides the speech bubble based on player proximity.
## [KR] 이벤트 진행 중이거나 타임라인 재생 중이면 무시한다.
## [EN] Ignored during event progression or timeline playback.
func near_player(near:bool)->void:
	if GameEvents.game_state == Constants.STATE_EVENT or Dialogic.current_timeline:
		return
	if near:
		text_bubble.is_show(true)
	else:
		text_bubble.is_show(false)

## [KR] 경험치를 획득한다. 최대 레벨이면 무시하며, 초과분은 집사 전용 스택에 저장.
## [EN] Acquires experience. Ignored at max level; overflow is stored in butler-exclusive stack.
## [KR] [param exp_param]만큼 [member love_exp]를 증가시킨다.
## [EN] Increases [member love_exp] by [param exp_param].
func get_exp(exp_param : int):
	if love_level >= Constants.PARTNER_MAX_LEVEL:
		return
	if love_exp < target_love_exp:
		love_exp += exp_param
		
		if is_max_exp():
			var overflow := love_exp - target_love_exp
			love_exp = target_love_exp
			
			if npc_name == Constants.NpcTypes.BUTLER and overflow > 0:
				MetaProgression.set_butler_stack_exp(overflow)
			
			if npc_name == Constants.NPC_OL or npc_name == Constants.NPC_GYARU:
				GameEvents.emit_npc_level_up_wating(self)
			else:
				pass
	else:
		# [KR] 이미 target_love_exp 이상인 상태에서 exp가 들어온 경우
		# [EN] When exp is received while already at or above target_love_exp
		if npc_name == Constants.NpcTypes.BUTLER:
			MetaProgression.set_butler_stack_exp(exp_param)

## [KR] 경험치가 목표치 이상인지 확인한다. 도달하면 [signal exp_max]를 발생시킨다.
## [EN] Checks if experience has reached the target. Emits [signal exp_max] when reached.
func is_max_exp()-> bool:
	if love_exp >= target_love_exp:
		exp_max.emit(npc_name)
		return true
	else:
		return false
		
	
## [KR] 호감도 레벨업을 실행한다. [member love_exp]를 초기화하고 [signal love_level_up_event]를 발생시킨다.
## [EN] Executes affection level-up. Resets [member love_exp] and emits [signal love_level_up_event].
func love_level_up():
	if love_exp < 100:
		return
	if is_max_level():
		NotionEvent.notion("호감도가 최대 단계에 도달했습니다", Constants.SD_ICONS[npc_name])
	love_level += 1
	love_exp = 0
	
	love_level_up_event.emit(npc_name)
	print("Love level increased! Current love level: " + str(love_level))
	
## [KR] 현재 호감도가 최대 레벨에 도달했는지 확인한다.
## [EN] Checks if current affection has reached the maximum level.
func is_max_level()->bool:
	if love_level >= Constants.PARTNER_MAX_LEVEL:
		return true
	else:
		return false

## [KR] Dialogic 타임라인 시작 시 호출. 현재 대화 대상 NPC이면 카메라 우선순위를 올리고 플레이어를 바라본다.
## [EN] Called when Dialogic timeline starts. Raises camera priority and looks at player if this NPC is the current dialogue target.
func _on_timeline_started():
	var partner_manager = get_tree().get_first_node_in_group("partnermanager") as PartnerManager
	if partner_manager.current_talker == npc_name:
		npc_camera.set_priority(100)
		var ch = get_tree().get_first_node_in_group("player")
		if not npc_camera.get_follow_targets().has(ch.visual):
			npc_camera.append_follow_targets(ch.visual)
		text_bubble.is_show(false)
		look_player(ch)

## [KR] Dialogic 타임라인 종료 시 호출. 카메라·위치·서브 애니메이션을 원래 상태로 복원한다.
## [EN] Called when Dialogic timeline ends. Restores camera, position, and sub-animation to original state.
func _on_timeline_ended():
	var ch = get_tree().get_first_node_in_group("player") as Player
	if is_instance_valid(ch):
		npc_camera.erase_follow_targets(ch.visual)
	npc_camera.set_priority(0)	
	if free_action_component.is_full_mode:
		free_action_component.scene_mode(false)
	
	positionY_reset(ch)
	
	## [KR] 이벤트 전 기본 위치가 저장되어 있으면 원래 위치로 복원한다.
	## [EN] Restores to original position if base position before event was saved.
	if event_position_component.base_position_enable:
		position = event_position_component.get_base_position()

	sub_anim_queue_free()

## [KR] 플레이어·NPC의 Y좌표가 전차 바깥(360 초과)이면 안전 범위로 보정한다.
## [EN] Corrects Y-coordinate to safe range if player/NPC is outside the train (above 360).
func positionY_reset(ch: Player):
	if self.position.y > 360:
		position.y = 348
	if ch.position.y > 360:
		ch.position.y = 348

## [KR] NPC 위치 변경 이벤트 핸들러. 자신의 타입과 일치하면 위치를 갱신한다.
## [EN] NPC position change event handler. Updates position if matching own type.
func _on_npc_position_change(npc_type: int, move_position: Vector2):
	if npc_type == npc_name:
		position = move_position

## [KR] 특정 NPC를 지정하여 애니메이션을 변경한다. 자신의 타입이면 [method anim_change]를 호출.
## [EN] Changes animation for a specific NPC. Calls [method anim_change] if matching own type.
func anim_change_this_npc(_str: String, npc_type: int):
	if npc_type == npc_name:
		anim_change(_str)

## [KR] 애니메이션을 변경한다. [code]"scene"[/code] 접두사가 있으면 H씬을 재생하고,
## [EN] Changes animation. Plays H-scene if prefixed with [code]"scene"[/code],
## [KR] 그렇지 않으면 일반 idle/기타 애니메이션으로 전환한다.
## [EN] otherwise switches to normal idle/other animation.
func anim_change(_str: String):
	if not _str.begins_with("scene"):
		_str = get_idle_anim_type(_str)
		sub_anim_hide()
		free_action_component.hide_current_scene()
		animation_player.play(_str)
		text_bubble.set_bubble_position() # [KR] 애니메이션 변경시 말풍선 위치 재조정 / [EN] Readjust speech bubble position on animation change
		return
	
	var parts = _str.split("_")
	var scene_str = parts[0].replace("scene", "")
	var scene = int(scene_str)

	position_setting(scene)
	
	play_scene(scene, _str)

## [KR] [code]idle[/code] 애니메이션 요청 시, NPC 스토리 진행 상태에 따라
## [EN] When [code]idle[/code] animation is requested, based on NPC story progression state,
## [KR] 실제 재생할 idle 변형(예: [code]idle_2[/code], [code]bind[/code])을 결정한다.
## [EN] determines the actual idle variant to play (e.g., [code]idle_2[/code], [code]bind[/code]).
func get_idle_anim_type(anim_name: String)-> String:
	if anim_name == "idle":
		match npc_name:
			Constants.NPC_BUTLER:
				if MetaProgression.has_read_event("chapter4_butler3"):
					return "idle_2"
			Constants.NPC_KONIAL:
				if MetaProgression.has_read_event("chapter5_complete"):
					return "bind"
		return "idle"
	else:
		return anim_name

## [KR] H씬 애니메이션을 재생한다. [param scene] > 100이면 풀스크린 씬, 그 외는 일반 씬.
## [EN] Plays H-scene animation. Fullscreen scene if [param scene] > 100, normal scene otherwise.
## [KR] 동시에 사용하지 않는 반대쪽 씬의 애니메이션은 정지시킨다.
## [EN] Stops animation of the unused opposite scene simultaneously.
func play_scene(scene: int, _str: String):
	
	sub_anim_show()
	
	var h_scene_data = free_action_component.h_scene_data as HSceneData
	var target_scene
	var unhandled_scene # [KR] 이전 씬, 혹은 사용하지 않는 씬 / [EN] Previous scene or unused scene
	if scene > 100:
		if !npc_sub_full_scene: # [KR] 풀 씬 재생할때 / [EN] When playing full scene
			npc_sub_full_scene = h_scene_data.get_full_scene(npc_name, scene) as NpcFullScene
			sub_full_scene_canvas.add_child(npc_sub_full_scene)
		if npc_sub_scene: # [KR] 사용 안하는 씬을 지정한다 / [EN] Designate the unused scene
			unhandled_scene = npc_sub_scene
		target_scene = npc_sub_full_scene
	else:
		if !npc_sub_scene: # [KR] 일반 씬 재생할 때 / [EN] When playing normal scene
			npc_sub_scene = h_scene_data.get_h_scene(npc_name, scene) as HScene
			npc_sub_scene.npc_type = npc_name
			sub_anim_container.add_child(npc_sub_scene)
		if npc_sub_full_scene: # [KR] 사용 안하는 씬을 지정한다 / [EN] Designate the unused scene
			unhandled_scene = npc_sub_full_scene
		target_scene = npc_sub_scene
	
	var anim_player = target_scene.get_child(0) as AnimationPlayer
	var unhandled_anim_player : AnimationPlayer
	if unhandled_scene:
		unhandled_anim_player = unhandled_scene.get_child(0) as AnimationPlayer
	if anim_player:
		anim_player.play(_str)
		animation_player.stop()
		npc_sprite.hide()
	if unhandled_anim_player:
		unhandled_anim_player.stop()
	unhandled_scene = null
	

## [KR] 회상방에서 H씬 종료 후 NPC를 idle 상태로 복원한다.
## H씬 중 본체 스프라이트([member npc_sprite])가 hide되고 애니메이션이 stop되므로,
## 스프라이트를 다시 켜고 기존 idle 전환 로직([method anim_change])으로 애니메이션을 재생한다.
## (회상방은 NPC가 영구 노드라 직접 되돌려야 함)
func restore_to_idle() -> void:
	if npc_sprite:
		npc_sprite.show()
	anim_change("idle")
	# H씬 시작 시 좌석으로 옮겨진 위치를 이벤트 전 위치로 되돌린다.
	# (_on_timeline_ended와 동일 로직. get_base_position은 1회성 소비라 이후 중복 복원 안 됨)
	if event_position_component.base_position_enable:
		position = event_position_component.get_base_position()

## [KR] NPC 좌표를 직접 변경한다. [param _x] 또는 [param _y]가 0이면 해당 축은 변경하지 않는다.
## [EN] Directly changes NPC coordinates. If [param _x] or [param _y] is 0, that axis is not changed.
func on_position_change(npc_type: int, _x:int, _y:int):
	if npc_type != npc_name:
		return
	if _x != 0:
		position.x = _x
	if _y != 0:
		position.y = _y

## [KR] NPC 좌우 반전 이벤트 핸들러. 자신의 타입이면 [method set_flip]을 호출한다.
## [EN] NPC horizontal flip event handler. Calls [method set_flip] if matching own type.
func _on_npc_flip(npc_type: int, flip: bool):
	if npc_type != npc_name:
		return
	set_flip(flip)

## [KR] H씬 재생 시 NPC와 플레이어의 위치를 씬 데이터 기반으로 조정한다.
## [EN] Adjusts NPC and player positions based on scene data during H-scene playback.
## [KR] 이동 전 위치를 [member event_position_component]에 저장하여 종료 후 복원할 수 있게 한다.
## [EN] Saves pre-move position to [member event_position_component] for restoration after completion.
func position_setting(scene: int):
	event_position_component.set_base_position(position) # [KR] 이동 전 위치 기억 / [EN] Remember position before move
	var scene_position:Vector2 = HSceneData.get_h_scene_position(h_scene_data_array, npc_name, scene)
	var ch = get_tree().get_first_node_in_group("player")
	if scene_position.x != 0:
		if ch:
			ch.position.x = scene_position.x
		position.x = scene_position.x
	if scene_position.y != 0:
		if ch:
			ch.position.y = scene_position.y
		position.y = scene_position.y


## [KR] 카메라 우선순위 및 오프셋을 변경한다. 타임라인에서 연출용으로 사용.
## [EN] Changes camera priority and offset. Used for direction in timelines.
func _on_camera_order_change(npc_type : int ,value : int, offset_x: int = 0, offset_y: int = 0):
	if offset_x != 0:
		camera_position.position.x += offset_x
	if offset_y != 0:
		camera_position.position.y += offset_y
	if npc_type == npc_name:
		#print(Dialogic.VAR.npc.get('type'))
		npc_camera.set_priority(value)
	var ch = get_tree().get_first_node_in_group("player")
	npc_camera.erase_follow_targets(ch.visual)
	#print(npc_camera.get_follow_targets())

## [KR] 카메라 위치를 초기 기준값([member base_camera_position])으로 복원한다.
## [EN] Restores camera position to the initial reference value ([member base_camera_position]).
func set_base_camera_position(npc_type: int):
	if npc_type == npc_name:
		if camera_position.position != base_camera_position:
			camera_position.position = base_camera_position

## [KR] NPC 탐색(찾기) 시 랜덤 위치·애니메이션·반전을 설정한다.
## [EN] Sets random position, animation, and flip when searching (finding) an NPC.
func set_find_position():
	var rand_position = randi_range(0,2)
	var find_position = event_position_component.set_find_position(rand_position)
	position = set_rand_tune_position(find_position)
	var rand_anim = randi_range(0,3)
	var rand_flip = bool(randi_range(0,1))
	set_find_anim(rand_anim)
	set_flip(rand_flip)
	
	# 위치 테스트를 위한 코드
	#push_warning("테스트중!")
	#position.x = 1620

## [KR] 기본 위치에 X/Y 랜덤 오프셋을 더해 자연스러운 배치 편차를 만든다.
## [EN] Adds random X/Y offset to the base position to create natural placement variation.
func set_rand_tune_position(basic_pos: Vector2)-> Vector2:
	var random_offset_x = randi_range(-250, 250)
	var random_offset_y = randi_range(0, 30)

	basic_pos += Vector2(random_offset_x,random_offset_y)
	#print("y_offset %d" %random_offset_y)
	return basic_pos

## [KR] 탐색 시 NPC에게 랜덤 애니메이션을 재생한다. 이변(anomaly) NPC이면 변경하지 않는다.
## [EN] Plays a random animation on the NPC during search. Does not change if anomaly NPC.
func set_find_anim(anim_num : int):
	if floor_manager.current_level:
		if not floor_manager.current_level.npc_anomaly == null:
			return
	match anim_num:
		0:
			animation_player.play("find1")
		1:
			animation_player.play("find2")
		2:
			animation_player.play("find3")
		3:
			animation_player.play("idle")

	text_bubble.set_bubble_position()

## [KR] NPC 스프라이트의 좌우 반전을 설정한다. [code]false[/code] = 왼쪽, [code]true[/code] = 오른쪽.
## [EN] Sets horizontal flip of the NPC sprite. [code]false[/code] = left, [code]true[/code] = right.
func set_flip(flip:= false):
	npc_sprite.flip_h = flip

## [KR] 베이스 스테이지에서 NPC가 플레이어 방향을 바라보도록 스프라이트를 반전한다.
## [EN] Flips the sprite so the NPC faces the player direction on the base stage.
## [KR] 특정 애니메이션 상태에서는 바라보기를 건너뛴다([code]NpcData.can_player_look[/code] 체크).
## [EN] Skips looking in certain animation states ([code]NpcData.can_player_look[/code] check).
func look_player(ch : Player):
	if floor_manager.current_level.stage_type != Constants.TYPE_BASE:
		return
	var npc_data = NpcData.new()
	if not npc_data.can_player_look(npc_name, animation_player.current_animation):
		return
	
	
	if self.global_position.x > ch.global_position.x:
		set_flip(false)
	else:
		set_flip(true)

## [KR] Dialogic 시그널 핸들러. [code]npc_set_front/mid/end[/code] 시그널로 NPC 위치를 재배치한다.
## [EN] Dialogic signal handler. Repositions NPC via [code]npc_set_front/mid/end[/code] signals.
func _on_dialogic_signal(arg: String):
	var position_int := -1
	
	if arg == "npc_set_front":
		position_int = event_position_component.FIND_FRONT
	if arg == "npc_set_mid":
		position_int = event_position_component.FIND_MID
	if arg == "npc_set_end":
		position_int = event_position_component.FIND_BACK
	
	if position_int == -1:
		return
	
	var find_position = event_position_component.set_find_position(position_int)
	position = set_rand_tune_position(find_position)
	var rand_anim = randi_range(0,3)
	var rand_flip = bool(randi_range(0,1))
	set_find_anim(rand_anim)
	set_flip(rand_flip)

## [KR] 서브 애니메이션 컨테이너(일반+풀스크린)를 숨기고 애니메이션을 정지한다.
## [EN] Hides sub-animation containers (normal + fullscreen) and stops animations.
func sub_anim_hide():
	sub_anim_container.hide()
	sub_full_scene_canvas.hide()
	sub_anim_play(false)

## [KR] 서브 애니메이션 컨테이너(일반+풀스크린)를 표시하고 애니메이션을 재개한다.
## [EN] Shows sub-animation containers (normal + fullscreen) and resumes animations.
func sub_anim_show():
	sub_anim_container.show()
	sub_full_scene_canvas.show()
	sub_anim_play(true)

## [KR] [param state]에 따라 서브 애니메이션을 재생하거나 정지한다.
## [EN] Plays or stops sub-animations based on [param state].
## [KR] 숨겨진 상태에서도 사운드가 계속 재생되는 문제를 방지하기 위해,
## [EN] To prevent sound from continuing to play while hidden,
## [KR] visible이 꺼질 때 애니메이션을 함께 정지시킨다.
## [EN] stops animations together when visible is turned off.
func sub_anim_play(state: bool):
	if npc_sub_scene:
		npc_sub_scene.current_anim_play(state)
	if npc_sub_full_scene:
		npc_sub_full_scene.current_anim_play(state)

## [KR] 서브 씬 인스턴스(일반·풀스크린)를 메모리에서 해제한다.
## [EN] Frees sub-scene instances (normal and fullscreen) from memory.
func sub_anim_queue_free():
	if is_instance_valid(npc_sub_scene):
		npc_sub_scene.queue_free()
	if is_instance_valid(npc_sub_full_scene):
		npc_sub_full_scene.queue_free()
