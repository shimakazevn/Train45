## 화면 밖 아이템 마커 UI.
## 드롭 아이템이 카메라 밖에 있을 때 좌우 화살표 마커를 트윈 애니메이션으로 표시하여
## 플레이어에게 아이템 위치 방향을 알린다.
extends Control
class_name ScreenOutItemMarker


## 드롭 아이템 관리자 참조.
@export var drop_item_manager: DropItemManager
## 메인 카메라 참조 (화면 범위 판단용).
@export var main_camera: Camera2D

## 현재 추적 중인 [DropItem] 배열.
var current_drop_items: Array[DropItem] = []

## 왼쪽 방향 마커.
@onready var item_marker_l: TextureRect = $ItemMarkerL
## 오른쪽 방향 마커.
@onready var item_marker_r: TextureRect = $ItemMarkerR

## 왼쪽 마커 트윈.
var tween_l: Tween
## 오른쪽 마커 트윈.
var tween_r: Tween

## 왼쪽 마커 아이콘.
@onready var item_icon_l: TextureRect = $ItemMarkerL/ItemIconL
## 오른쪽 마커 아이콘.
@onready var item_icon_r: TextureRect = $ItemMarkerR/ItemIconR

## 왼쪽 마커 직전 표시 상태.
var last_left_state := false
## 오른쪽 마커 직전 표시 상태.
var last_right_state := false

## 왼쪽 마커 숨김 위치 X.
const OUT_POS_L: float = -30
## 왼쪽 마커 표시 위치 X.
const IN_POS_L: float = 10
## 오른쪽 마커 숨김 위치 X.
const OUT_POS_R: float = 650
## 오른쪽 마커 표시 위치 X.
const IN_POS_R: float = 609


## 시그널 연결 및 마커 초기 위치를 설정한다.
func _ready() -> void:
	GameEvents.stage_change.connect(_on_stage_changed)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
	item_marker_l.show()
	item_marker_r.show()
	item_marker_l.position.x = OUT_POS_L
	item_marker_r.position.x = OUT_POS_R

## 타임라인 시작 시 모든 마커를 숨긴다.
func _on_timeline_started():
	set_all_visible(false)

## 타임라인 종료 시 모든 마커를 표시한다.
func _on_timeline_ended():
	set_all_visible(true)

## [param item]을 추적 목록에 추가하고 화면 진입/퇴장 시그널을 연결한다.
func add_drop_items(item: DropItem):
	current_drop_items.append(item)
	item.screen_notifier.screen_entered.connect(_screen_state_changed.bind(item))
	item.screen_notifier.screen_exited.connect(_screen_state_changed.bind(item))
	item.tree_exiting.connect(_on_item_free.bind(item))


## 아이템의 화면 진입/퇴장 콜백. 한 프레임 뒤에 마커를 갱신한다.
func _screen_state_changed(_item: DropItem):
	if not is_inside_tree(): # 씬 해체 중 트리에서 빠진 상태면 get_tree() 가 null 이므로 중단
		return
	await get_tree().physics_frame # 티켓 생성되자마자 신호 뿌리는 걸 방지하기 위해 한 프레임 뒤에 실행되도록
	if not is_inside_tree(): # await 사이에 트리에서 빠졌을 수 있으므로 재확인
		return
	_update_markers()


## 모든 드롭 아이템의 위치를 확인하여 좌우 마커 표시 여부를 갱신한다.
## 카메라 기준으로 왼쪽/오른쪽에 화면 밖 아이템이 있는지 판별한다.
func _update_markers():
	var left_out := false
	var right_out := false
	var camera_x := main_camera.position.x

	for item in current_drop_items:
		if not is_instance_valid(item):
			continue
		
		if not item.screen_notifier.is_on_screen():
			var item_pos := item.global_position
			
			if item_pos.x < camera_x:
				left_out = true
			elif item_pos.x > camera_x:
				right_out = true
	
	# 마커 표시 갱신
	if left_out != last_left_state:
		set_item_marker_tween(item_marker_l, left_out, OUT_POS_L, IN_POS_L)
		last_left_state = left_out
	
	if right_out != last_right_state:
		set_item_marker_tween(item_marker_r, right_out, OUT_POS_R, IN_POS_R)
		last_right_state = right_out



## 아이템이 해제될 때 추적 목록에서 제거한다.
func _on_item_free(item: DropItem):
	current_drop_items.erase(item)
	#_update_markers()

## [param marker]를 트윈으로 슬라이드 인/아웃한다.
## [param should_show]가 [code]true[/code]이면 [param in_pos_x]로, [code]false[/code]이면 [param out_pos_x]로 이동한다.
func set_item_marker_tween(marker: TextureRect, should_show: bool, out_pos_x: float, in_pos_x: float):
	#print( "tweeing")
	
	var tween: Tween
	match marker:
		item_marker_l:
			tween = tween_l
		item_marker_r:
			tween = tween_r
	tween = create_tween()
	
	if should_show:
		tween.tween_property(marker, "position:x", in_pos_x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		tween.tween_property(marker, "position:x", out_pos_x, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		

## 좌우 마커를 모두 표시하거나 숨긴다.
func set_all_visible(should_show: bool):
	if should_show:
		item_marker_l.show()
		item_marker_r.show()
	else:
		item_marker_l.hide()
		item_marker_r.hide()

## 스테이지 변경 시 좌우 마커를 모두 숨김 위치로 트윈한다.
func _on_stage_changed():
	set_item_marker_tween(item_marker_l, false, OUT_POS_L, IN_POS_L)
	set_item_marker_tween(item_marker_r, false, OUT_POS_R, IN_POS_R)
