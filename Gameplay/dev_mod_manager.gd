## 개발자 모드 UI를 관리하고 치트 명령을 처리하는 매니저 노드.
## 키 입력으로 개발자 패널을 토글하며, [DevModeButton]별 치트 기능을 실행한다.
extends Node

## 테스트용 레벨 [PackedScene] 배열. [method set_dest_info]에서 사용된다.
@export var levels: Array[PackedScene]

## 치트 버튼이 배치된 [GridContainer].
@export var dev_buttons_container: GridContainer
## 개발자 모드 UI를 포함하는 [CanvasLayer].
@onready var canvas_layer: CanvasLayer = $CanvasLayer
## 테스터 ID를 표시하는 [Label].
@export var tester_id_label: Label
## 현재 버전을 표시하는 [Label].
@export var ver_label: Label

const STAGE_PICKER_SCENE := preload("res://Gameplay/stage_picker.tscn")

## 개발자 모드 활성화 여부.
var dev_mode_enable: bool = false
## 현재 열려 있는 스테이지 선택 팝업 참조.
var _stage_picker: Control = null

## 치트 호감도 경험치 기본 수치.
const DEV_LOVE_EXP: int = 25

## 노드 준비 시 버전 라벨을 설정하고, 개발자 패널을 숨긴 뒤 각 치트 버튼의 시그널을 연결한다.
func _ready() -> void:
	canvas_layer.visible = false
	if not OS.is_debug_build() and not Constants.CHEAT_IN_RELEASE:
		return

	var version: String = ProjectSettings.get_setting("application/config/version")
	ver_label.text = "v" + version

	tester_id_label.text = MetaProgression.TESTER

	for i in dev_buttons_container.get_children():
		var button : DevModeButton = i
		button.pressed.connect(_button_pressed.bind(button.cheat_name))

## [param cheat_name]에 따라 해당 치트 기능을 실행한다.
## 티켓 증가, 아이템 드롭, NPC 호감도/에로 게이지 증가, 언어 변경, 스테이지 클리어 등을 지원한다.
func _button_pressed(cheat_name: String):
	match cheat_name:
		"ticket_up":
			GameEvents.emit_set_ticket("plus", 1000)
		"ticket_drop":
			GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, 50)
		"butler_love_drop":
			GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.BUTLER_HEART, Constants.INCRESE_LOVE_EXP_NUM_BUTLER)
		"love_up_reina":
			GameEvents.emit_get_npc_exp(DEV_LOVE_EXP, GameEvents.NpcTypes.REINA)
		"love_up_mai":
			GameEvents.emit_get_npc_exp(DEV_LOVE_EXP, GameEvents.NpcTypes.MAI)
		"love_up_konial":
			GameEvents.emit_get_npc_exp(100, GameEvents.NpcTypes.KONIAL)
		"love_up_butler":
			GameEvents.emit_get_npc_exp(100, GameEvents.NpcTypes.BUTLER)
		"ero_gauge_up_reina":
			GameEvents.emit_get_ero_gauge(100, GameEvents.NpcTypes.REINA)
		"ero_gauge_up_mai":
			GameEvents.emit_get_ero_gauge(100, GameEvents.NpcTypes.MAI)
		"tr_ko":
			LanguageManager.change_language("ko")
		"tr_jp":
			LanguageManager.change_language("jp")
		"tr_zh":
			LanguageManager.change_language("zh")
		"tr_cn":
			LanguageManager.change_language("cn")
		"tr_en":
			LanguageManager.change_language("en")
		"tr_vi":
			LanguageManager.change_language("vi")
		"stage_clear":
			var floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
			if floor_manager and floor_manager.current_level:
				GameEvents.emit_stage_clear()
				floor_manager.stage_clear(floor_manager.current_level)
			else:
				GameEvents.emit_stage_clear()
		"pick_next_stage":
			_toggle_stage_picker()
		"save_dest_info":
			set_dest_info()
		"qa_bot_toggle":
			get_node("/root/QABot").toggle()
		"reset_achievements":
			SteamManager.reset_all()


## 입력 이벤트를 감지하여 [code]"dev_mode_toggle"[/code] 액션 시 개발자 모드를 전환한다.
func _input(event):
	if not OS.is_debug_build() and not Constants.CHEAT_IN_RELEASE:
		return
	if event.is_action_pressed("dev_mode_toggle"):
		set_dev_mode()

## [member dev_mode_enable]을 토글하고, 개발자 패널의 표시 상태를 갱신한다.
func set_dev_mode():
	dev_mode_enable = !dev_mode_enable
	if dev_mode_enable:
		canvas_layer.visible = true
	else:
		canvas_layer.visible = false

## 스테이지 선택 팝업을 토글한다. 이미 열려 있으면 닫고, 없으면 씬을 인스턴스화하여 연다.
func _toggle_stage_picker() -> void:
	if is_instance_valid(_stage_picker):
		_stage_picker.queue_free()
		_stage_picker = null
		return

	var floor_manager := get_tree().get_first_node_in_group("floormanager") as FloorManager
	_stage_picker = STAGE_PICKER_SCENE.instantiate()
	_stage_picker.tree_exiting.connect(func(): _stage_picker = null)
	canvas_layer.add_child(_stage_picker)
	_stage_picker.setup(floor_manager)


## 임시로 메타데이터에 모든 레벨의 목적지 정보를 강제 저장한다.
## [member levels] 배열의 각 레벨을 인스턴스화하여 [code]MetaProgression[/code]에 기록한다.
func set_dest_info():
	var route_data: RouteData = RouteData.new()
	for i in levels:
		var level: Level = i.instantiate()
		MetaProgression.set_current_destination_info(level.get_scene_file_path(), route_data.get_destination_data(level))
