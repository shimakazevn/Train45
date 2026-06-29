## 칸칸네비 타이틀 UI 컴포넌트.
## 노선도 종착점 설정 여부에 따라 현재 목적지 정보를 화면 상단에 표시하며,
## 스테이지 전환·파트너 변경 시 자동으로 갱신한다.
extends Control

## UI 슬라이드 애니메이션용 [Tween].
var tween: Tween
## 현재 [FloorManager] 참조.
@export var floor_manager: FloorManager
## 현재 [PartnerManager] 참조.
@export var partner_manager: PartnerManager
## 노선도 설정 관리자.
@export var setting_route_manager: SettingRouteManager
## 노선 데이터 유틸리티.
var route_data: RouteData = RouteData.new()
## 메인 네비 라벨.
@onready var navi_label: Label = %NaviLabel
## 서브 네비 라벨 (목적지 이름 표시).
@onready var navi_sub_label: Label = %NaviSubLabel
## 라벨 컨테이너 (일반 모드용).
@onready var route_text_container: Control = $RouteTextContainer
## 종착역 전용 라벨 (완료 스테이지용).
@onready var navi_destination_label: Label = $NaviDestinationLabel

## 파트너 아이콘 프레임.
@onready var partner_frame: TextureRect = $RouteTextContainer/PartnerFrame
## 파트너 아이콘 텍스처.
@onready var partner_icon: TextureRect = $RouteTextContainer/PartnerFrame/PartnerIcon

## UI가 현재 화면에 표시 중인지 여부.
var is_ui_show: bool = false

## UI 기본 위치.
var base_position: Vector2
## UI 숨김 시 오프셋 위치.
const UI_OUT_POSITION :Vector2 = Vector2(0,-50)
## 종착점 미지정 시 표시할 텍스트 키.
const TEXT_ROUTE_BLANK: String = "NOW_DESTINATION_NOTHING"
## 종착점 텍스트 포맷 문자열.
const TEXT_ROUTE:String = "%s"

## 노선 힌트 데이터.
var hint_info : RouteHintData = RouteHintData.new()


## 시그널 연결 및 초기 위치·가시성을 설정한다.
func _ready() -> void:
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	GameEvents.stage_change.connect(_on_stage_change)
	GameEvents.in_next_stage.connect(_on_in_next_stage)
	partner_manager.partner_change.connect(_on_partner_changed)
	setting_route_manager.route_update.connect(_is_route_update)
	
	base_position = position
	position = position + UI_OUT_POSITION
	partner_frame.hide()
	set_visible_label(true)

## 라벨 표시 모드를 설정한다.
## [param normal]이 [code]true[/code]이면 일반 라벨, [code]false[/code]이면 종착역 라벨을 표시한다.
func set_visible_label(normal: bool = true):
	if normal:
		route_text_container.show()
		navi_destination_label.hide()
	else:
		route_text_container.hide()
		navi_destination_label.show()

## 스테이지 변경 콜백. UI 정보를 갱신한다.
func _on_stage_change():
	update_ui_info()

## 노선도 업데이트 콜백. 지연 호출로 UI 정보를 갱신한다.
func _is_route_update():
	call_deferred("update_ui_info")

## 다음 스테이지 진입 시 UI를 슬라이드 아웃한다.
func _on_in_next_stage():
	set_ui_inout(false)


## 현재 노선도 상태에 따라 UI 정보를 갱신한다.
## 종착점이 설정된 경우 스테이지 타입별로 라벨과 파트너 아이콘을 업데이트하고,
## 미설정 시 UI를 숨긴다.
func update_ui_info():
	## 종착점 지정이 된 경우 UI를 표시한다
	if setting_route_manager.setting_route_on(): 
		var type:int = floor_manager.current_level.stage_type
		var current_destination_info := setting_route_manager.get_current_destination_info()
		
		partner_frame.hide()
		if current_destination_info:
			set_partner_icon(current_destination_info)
		
		## 스테이지 타입에 따라 출력되는 레이블 종류를 변경한다
		if type == Constants.TYPE_COMPLETE:
			if current_destination_info == {}:
				navi_destination_label.text = "DEST_PERCENT"
			else:
				navi_destination_label.text = current_destination_info["title"]
			set_visible_label(false)
		else:
			set_visible_label(true)

		if type == Constants.TYPE_BASE:
			navi_label.text = "NOW_DESTINATION_COMFIRMED"
			if current_destination_info == {}:
				navi_sub_label.text = TEXT_ROUTE_BLANK
			else:
				navi_sub_label.text = TEXT_ROUTE%tr(current_destination_info["title"])
				
			set_ui_inout(true)
		else:
			navi_label.text = route_data.get_route_title(floor_manager.current_level)
			set_ui_inout(true)
	else:
		set_ui_inout(false)


## UI를 바운스 트윈으로 슬라이드 인/아웃한다.
## [param target_in]이 [code]true[/code]이면 기본 위치로, [code]false[/code]이면 화면 밖으로 이동한다.
func set_ui_inout(target_in: bool):
	tween = create_tween()
	
	var target_position: Vector2
	if target_in:
		target_position = base_position
	else:
		target_position = position + UI_OUT_POSITION
	
	is_ui_show = target_in
	tween.tween_property(self, "position", target_position, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


## 타임라인 시작 시 UI를 숨긴다.
func _on_timeline_started():
	hide()

## 타임라인 종료 시 UI를 다시 표시한다.
func _on_timeline_ended():
	show()

## 종착점 정보의 힌트 데이터에서 파트너 아이콘을 설정한다.
## 현재 파트너와 일치하면 밝게, 불일치하면 어둡게 표시한다.
func set_partner_icon(current_destination_info: Dictionary):
	if current_destination_info == {}:
		return
	
	var hint_res :RouteHintPage= hint_info.get_route_hint(current_destination_info["hint_id"])

	if hint_res.partner_type != RouteHintPage.PartnerType.NONE:
		partner_frame.show()
		partner_icon.texture = Constants.SD_ICONS[hint_res.partner_type]
		if partner_manager.current_partner == hint_res.partner_type:
			partner_icon.self_modulate = Color.WHITE
		else:
			partner_icon.self_modulate = Color.DIM_GRAY

## 파트너 변경 콜백. UI가 표시 중이면 파트너 아이콘을 갱신한다.
func _on_partner_changed(_npc_type:PartnerManager.NpcType):
	if not is_ui_show:
		return
	set_partner_icon(setting_route_manager.get_current_destination_info())
