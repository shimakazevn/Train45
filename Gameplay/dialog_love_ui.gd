## 대화 시 호감도 바 UI.
## NPC와 대화할 때 현재 호감도 경험치 바와 레벨을 표시한다.
## 거점 스테이지에서만 작동하며, 호감도 해금 조건을 만족해야 표시된다.
extends Control

## Dialogic 텍스트 패널 참조 (가시성 연동용).
@onready var dialog_text_panel: PanelContainer = %DialogTextPanel

## 현재 [FloorManager] 참조.
var floor_manager: FloorManager
## 현재 [PartnerManager] 참조.
var partner_manager: PartnerManager

## 호감도 경험치 프로그레스 바.
@export var LoveBar: TextureProgressBar
## 호감도 레벨 라벨.
@export var LoveLevel: Label

## 페이드 인 애니메이션용 [Tween].
var tween_show: Tween


## 시그널 연결 및 매니저 참조를 초기화한 뒤 대화 상태를 확인한다.
func _ready() -> void:
	self.visibility_changed.connect(_on_visible_changed)
	dialog_text_panel.visibility_changed.connect(_on_textbox_visible_changed.bind(dialog_text_panel))
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.Styles.style_changed.connect(_on_dialogic_style_changed)
	GameEvents.dialog_love_ui_hide_requested.connect(hide)
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	partner_manager = get_tree().get_first_node_in_group("partnermanager")
	hide()
	_on_talk()

## 현재 대화 중인 NPC의 호감도를 바에 반영하고 페이드 인으로 표시한다.
## 프롤로그·호감도 미해금·비거점 스테이지·suppress_love_ui 활성 시 표시하지 않는다.
func _on_talk():
	if GameEvents.suppress_love_ui:
		return
	if partner_manager == null:
		return
	
	var talker: int = partner_manager.current_talker
	var npc: Npc = partner_manager.partner[talker]
	
	if not is_npc_unlock_love(npc.npc_name) or floor_manager.current_prologue:
		return
	
	var current_npc = partner_manager.partner[npc.npc_name] as Npc
	if current_npc is Npc \
	and floor_manager.current_stage_type == Constants.TYPE_BASE and not GameEvents.is_recollection_room:
		var max_level: int = partner_manager.get_partner_max_level(npc.npc_name)
		if current_npc.love_level < max_level:
			LoveBar.max_value = current_npc.target_love_exp
			LoveBar.value = current_npc.love_exp
			LoveLevel.text = str(current_npc.love_level)
		else:
			LoveBar.max_value = current_npc.target_love_exp
			LoveBar.value = current_npc.target_love_exp
			LoveLevel.text = str("MAX")
		
		self.modulate = Color.TRANSPARENT
		if tween_show:
			tween_show.kill()
		tween_show = create_tween()
		tween_show.tween_property(self, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(1.5)
		show()

## 타임라인 시작 콜백. (현재 미사용)
func _on_timeline_started():
	pass

## 타임라인 종료 시 거점 스테이지이면 UI를 숨긴다.
## dtl에서 건 호감도 UI 억제는 타임라인 단위이므로 종료 시 해제한다.
func _on_timeline_ended():
	GameEvents.suppress_love_ui = false
	if floor_manager.current_stage_type == Constants.TYPE_BASE:
		hide()


## [param npc_type] NPC의 호감도 시스템이 해금되었는지 확인한다.
## 코니알은 구속 이벤트, 집사는 인간폼 이벤트 이후에 해금된다.
func is_npc_unlock_love(npc_type: int)-> bool:
	if npc_type == Constants.NPC_KONIAL:
		if not MetaProgression.has_read_event(Constants.QUESTLINE_KONIAL_BIND): #코니알 구속 이후부터 호감도아이콘 뜨게
			return false
	elif npc_type == Constants.NPC_BUTLER:
		if not MetaProgression.has_read_event(Constants.QUESTLINE_BUTLER_HUMAN): #집사 인간폼 이후부터 호감도아이콘 보이기
			return false
	return true

## Dialogic 스타일 변경 콜백. 풀씬 스타일일 경우 UI를 숨긴다.
func _on_dialogic_style_changed(info:Dictionary):
	if info["style"] == "fullscene_style":
		hide()

## 텍스트박스 가시성 변경 콜백. 텍스트박스가 숨겨지면 호감도 바도 숨긴다.
func _on_textbox_visible_changed(target: PanelContainer):
	if target.visible == false:
		hide()
	else:
		_on_talk()

## 자기 자신의 가시성 변경 콜백. (현재 미사용)
func _on_visible_changed():
	#print(visible)
	pass
