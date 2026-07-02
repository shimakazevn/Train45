## [KR] 귀신 도감 창. GhostData의 GhostRes들을 버튼으로 나열한다.
## base_0 HSceneSwitchWindow와 동일한 조작: 좌우로 고르고(포커스), 선택하면 그 귀신의
## 풀 H(player.rape())를 재생한다. H가 끝나면(find_faild) 갤러리로 복귀한다.
## (회상방은 단일 방이라 rape 종료의 시작지점 텔레포트를 TeleportComponent에서 차단한다.)
## ESC로 창을 닫는다.
extends CanvasLayer
class_name GhostGalleryWindow

## [KR] 목록에 생성할 버튼 씬(GhostGalleryButton).
@export var button_scene: PackedScene
## [KR] 버튼이 담길 컨테이너(HSceneSwitchWindow 비주얼의 RecollectionContainer).
@onready var ghost_list: Container = %RecollectionContainer
## [KR] 포커스된 버튼을 따라다니는 선택 프레임(있으면).
@onready var select_frame: Node = get_node_or_null("%SelectFrame")
## [KR] 귀신 H 모드 나가기 안내 라벨(recollect_rect의 ExitLabel과 동일 노드).
##      풀 H(rape) 재생 중엔 숨기고, 종료 시 다시 표시한다.
@onready var exit_label: CanvasItem = get_node_or_null("../RecollectionCanvas/ExitLabel")

const PLAYER_BASE_POS: Vector2 = Vector2(369.0, 370.0)

var player: Player
## [KR] 이 창을 연 도감 오브젝트(Ghosts). 선택(H 재생) 동안 숨기고 닫을 때 다시 표시.
var gallery: CanvasItem
var is_open := false
## [KR] rape(풀 H) 재생 중 여부. 이 동안 ESC = 뒤로가기(중단 → 갤러리 복귀).
var _rape_active := false

func _ready() -> void:
	player = _find_level_player()
	visible = false
	for c in ghost_list.get_children():
		c.queue_free()

## [KR] 도감 열기(브라우징). 플레이어를 고정(이동·차지 차단)하고 창을 띄운다(정지하지 않음).
func open(gallery_node: CanvasItem = null) -> void:
	gallery = gallery_node
	_build_list()
	visible = true
	is_open = true
	if player:
		player.is_ghost_play = true   # 이동/애님 idle 덮어쓰기 차단(브라우징 중 고정)
		player.set_find_lock(true)    # 창 중 차지/감지 차단
	# 이전 버튼 queue_free(지연 삭제)가 끝난 뒤 첫 새 버튼에 포커스를 잡는다.
	_grab_first_focus.call_deferred()

## [KR] 창 종료(ESC): 신음 정지, 플레이어 원복(idle), Ghosts 다시 표시.
func close() -> void:
	is_open = false
	visible = false
	if player:
		player.ghost_moan_stream.stop_moan()
		player.is_ghost_play = false
		player.set_find_lock(false)
		player.animation_player.play("idle")
	if gallery:
		gallery.show()

## [KR] 삭제 예정이 아닌 첫 새 버튼에 포커스를 잡는다(재열기 시 이전 버튼 free 후 호출).
func _grab_first_focus() -> void:
	if not is_open:
		return
	for c in ghost_list.get_children():
		if is_instance_valid(c) and not c.is_queued_for_deletion() and c is GhostGalleryButton:
			c.grab_focus()
			return

func _build_list() -> void:
	for c in ghost_list.get_children():
		c.queue_free()
	# HSceneData와 동일하게 폴더의 .tres를 일괄 로드한다.
	for res in TrainUtil.get_res_from_path(GhostData.GHOST_DATA_PATH):
		if not (res is GhostRes):
			continue
		var btn := button_scene.instantiate() as GhostGalleryButton
		ghost_list.add_child(btn)
		btn.setup(res)
		btn.selected.connect(_on_ghost_selected)
		# 포커스 시 선택 프레임을 해당 버튼으로 이동(HSceneSwitchWindow와 동일한 연출).
		btn.focus_entered.connect(_update_select_frame.bind(btn))

## [KR] 포커스된 버튼 위치로 선택 프레임을 옮긴다.
## follow_focus 스크롤/레이아웃이 반영된 뒤 global_position을 읽도록 한 프레임 대기한다.
func _update_select_frame(btn: Control) -> void:
	if not (select_frame and select_frame.has_method("set_frame_pos")):
		return
	await get_tree().process_frame
	if is_instance_valid(btn):
		select_frame.set_frame_pos(btn.global_position)

## [KR] 선택: 그 귀신의 풀 H(rape)를 재생한다. 창을 닫고 고정 해제 후 rape() 실행.
## rape 종료(find_faild)는 _on_rape_end가 받아 정리하고 갤러리를 재오픈한다.
func _on_ghost_selected(res: GhostRes) -> void:
	if not (player and res):
		return
	is_open = false
	visible = false
	_rape_active = true
	player.is_ghost_play = false   # rape가 STATE_RAPE로 제어하므로 갤러리 고정 해제
	player.set_find_lock(false)
	if gallery:
		gallery.hide()
	# 풀 H 재생 중엔 ESC 안내(나가기)를 숨긴다(rape 중 ESC는 무시되므로 오해 방지).
	if exit_label:
		exit_label.hide()
	if not player.find_faild.is_connected(_on_rape_end):
		player.find_faild.connect(_on_rape_end)
	player.position = PLAYER_BASE_POS
	player.rape(res.anim_name)

## [KR] rape 종료(find_faild) 시: 갤러리로 복귀.
func _on_rape_end() -> void:
	_return_to_gallery_from_rape()

## [KR] rape 정리 후 갤러리 재오픈(자연 종료·ESC 중단 공통).
func _return_to_gallery_from_rape() -> void:
	_rape_active = false
	if player.find_faild.is_connected(_on_rape_end):
		player.find_faild.disconnect(_on_rape_end)
	_cleanup_after_rape()
	# H 종료 → 갤러리 복귀: ESC 안내(나가기)를 다시 표시한다.
	if exit_label:
		exit_label.show()
	open(gallery)

## [KR] 회상방은 씬 전환(텔레포트)이 없으므로 rape가 남긴 상태/UI를 수동 정리한다.
func _cleanup_after_rape() -> void:
	player.enable() # input/visible/STATE_NORMAL + 신음 정지
	player.animation_player.play("idle")
	player.cum_sprite.hide()
	player.rape_sprite.show()
	player.rape_gauge_base.hide()
	player.keyboard_icon.hide()
	player.cum_delay_label.hide()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("esc"):
		return
	if is_open:
		# 브라우징 중 ESC: 창 닫기.
		close()
		get_viewport().set_input_as_handled()
	elif _rape_active:
		# H(rape) 재생 중엔 ESC 무시(중단 불가). pause 메뉴가 뜨지 않도록 입력만 소비한다.
		get_viewport().set_input_as_handled()

## [KR] 상위 트리에서 Level 루트를 찾아 그 player를 반환한다.
func _find_level_player() -> Player:
	var n: Node = self
	while n != null:
		if n is Level:
			return (n as Level).player
		n = n.get_parent()
	return null
