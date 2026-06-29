## 정념(에로) 게이지 바 UI.
## NPC와의 대화 시 정념 게이지를 표시하며, 게이지 변동과 스택을 시각적으로 반영한다.
## 레이나 또는 마이 파트너에게만 적용되고, 일정 호감도 레벨 이상일 때 활성화된다.
extends Control

## 현재 [FloorManager] 참조.
@export var floor_manager: FloorManager
## 현재 [PartnerManager] 참조.
@export var partner_manager: PartnerManager
## 정념 게이지 내부 프로그레스 바.
@onready var progress_bar: TextureProgressBar = $ProgressBar

## 정념 게이지 외부(스택) 프로그레스 바.
@onready var progress_bar_outer: TextureProgressBar = $ProgressBarOuter
## 게이지 스택 수치 라벨.
@onready var gauge_stack_lable: Label = $GaugeStackLable

## 페이드 인 애니메이션용 [Tween].
var tween_show: Tween
## inner 바 애니메이션용 [Tween].
var tween_inner: Tween
## outer 바 애니메이션용 [Tween].
var tween_outer: Tween
## _on_update_ui의 tween 목표값. 스택 업데이트 시 inner 즉시 반영에 사용.
var _tween_target_gage: int = 0

## 시그널 연결 및 초기 설정을 수행한다.
func _ready() -> void:
	progress_bar.max_value = Constants.PARTNER_MAX_ERO_GAUGE
	progress_bar_outer.max_value = Constants.PARTNER_MAX_ERO_GAUGE
	hide()
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	GameEvents.player_talk.connect(_on_talk)
	partner_manager.ero_gage_update.connect(_on_update_ui)
	partner_manager.ero_stack_update.connect(_on_update_stack_gauge)
	partner_manager.free_action_end.connect(_on_free_action_end)
	
	
## 대화 시작 콜백. 거점에서 일정 호감도 이상의 NPC와 대화 시 게이지를 페이드 인으로 표시한다.
func _on_talk(npc: Npc, _lable: String = ""):
	var current_npc = partner_manager.partner[npc.npc_name] as Npc
	if current_npc is Npc \
	and floor_manager.current_stage_type == Constants.TYPE_BASE \
	and current_npc.love_level >= NpcData.UNLOCK_LEVEL_BASE_H\
	and _get_talk_npc_is_ero_gauge_enable(npc.npc_name):
		progress_bar.value = current_npc.ero_gage
		progress_bar_outer.value = current_npc.ero_gage
		
		self.modulate = Color.TRANSPARENT
		tween_show = create_tween()
		tween_show.tween_property(self, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(1.0)
		show()
	
## 타임라인 시작 콜백. (현재 미사용)
func _on_timeline_started():
	pass

## 타임라인 종료 시 게이지 UI를 숨긴다.
func _on_timeline_ended():
	hide()

## 정념 게이지 값 업데이트 콜백.
## 현재 자유 H 파트너와 일치하는 경우에만 [Tween]으로 바 값을 애니메이션한다.
func _on_update_ui(_npc_type:PartnerManager.NpcType, gage: int):
	if _npc_type != partner_manager.current_free_h_partner:
		return
	
	_tween_target_gage = gage
	if visible == true:
		gauge_stack_lable.hide()
		if tween_inner: tween_inner.kill()
		if tween_outer: tween_outer.kill()
		tween_inner = create_tween()
		tween_inner.tween_property(progress_bar, "value", gage, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_outer = create_tween()
		tween_outer.tween_property(progress_bar_outer, "value", gage, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		progress_bar.value = gage

## 정념 게이지를 표시할 수 있는 파트너인지 확인한다.
## 레이나 또는 마이일 때만 [code]true[/code]를 반환한다.
func _get_talk_npc_is_ero_gauge_enable(npc_type: int)-> bool:
	return npc_type in [Constants.NpcTypes.REINA, Constants.NpcTypes.MAI]

## 정념 스택 게이지 업데이트 콜백.
## 외부 프로그레스 바를 스택만큼 차감하여 표시하고, 스택 라벨 위치를 갱신한다.
func _on_update_stack_gauge(npc_type:PartnerManager.NpcType, gauge: float):
	if npc_type != partner_manager.current_free_h_partner:
		return
	
	# inner: 즉시 최종값으로 점프
	if tween_outer and tween_outer.is_running():
		tween_outer.kill()
	
	_apply_stack_gauge(gauge)

## 스택 게이지 수치를 outer 바와 라벨에 반영한다.
## inner 트윈 진행 중이면 최종 목표값 기준으로 계산해 빨간 바가 정확한 위치로 즉시 이동한다.
func _apply_stack_gauge(gauge: float) -> void:
	
	var base := _tween_target_gage if (tween_inner and tween_inner.is_running()) else int(progress_bar.value)
	progress_bar_outer.value = base - gauge
	
	var bar_width = progress_bar_outer.texture_progress.get_width() * progress_bar_outer.scale.x
	var ratio = progress_bar_outer.value / float(progress_bar_outer.max_value)
	var end_y = progress_bar_outer.global_position.y - bar_width * ratio + progress_bar_outer.texture_progress_offset.y
	gauge_stack_lable.global_position.y = end_y - (gauge_stack_lable.size.y / 2) - 4
	gauge_stack_lable.update_gauge_stack(int(gauge))

## 자유 행동 종료 콜백. 스택 라벨을 숨긴다.
func _on_free_action_end():
	gauge_stack_lable.hide()
