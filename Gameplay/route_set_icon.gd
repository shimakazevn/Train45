## 칸칸네비(노선도) 버튼 아이콘.
## 노선도 맵을 열거나, 해금 조건·장착 아이템(팔찌)에 따른 활성/비활성 상태를 관리한다.
## 새 힌트 획득 시 바운스 애니메이션을 재생한다.
extends Button
class_name RouteSetIcon

## 튜토리얼 종료 시 발생하는 시그널.
signal tuto_end

## 노선도 맵 씬 경로.
const ROUTE_MAP = "res://Gameplay/route_map.tscn"
## 업그레이드 매니저 참조.
@export var upgrade_manager: UpgradeManager
## 노선도 설정 관리자 참조.
@export var setting_route_manager: SettingRouteManager
## 튜토리얼 블록 [PackedScene].
@export var tuto_block : PackedScene
## 노선도 맵을 자식으로 추가할 [CanvasLayer].
@onready var canvas_layer: CanvasLayer = $CanvasLayer
#@onready var highlight_shader: ColorRect = $HighlightShader

## 칸칸네비 사용 가능 여부. 팔찌 착용 시 [code]false[/code].
var is_enable := true
## 튜토 진행 중 Q 외 입력 차단 여부.
var is_tuto_blocking := false

## 시그널 연결 및 초기 활성 상태를 설정한다.
func _ready() -> void:
	GameEvents.update_equip_item.connect(_on_update_equip_item)
	MetaProgression.get_route_hint.connect(_on_get_route_hint)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	upgrade_manager.shop_state_changed.connect(_on_shop_state_changed)
	navi_on(true)
	set_is_disable(get_equip_konial_love_item())

## 버튼 클릭 시 칸칸네비를 연다.
func _on_pressed() -> void:
	kankan_on()

## 단축키 입력 시 칸칸네비를 연다. 다른 창이 열려 있거나 타임라인 중이면 무시한다.
## 튜토 차단 중에는 Q(kankannavi) 외 모든 입력을 소비한다.
func _input(event: InputEvent) -> void:
	if is_tuto_blocking:
		if event.is_action_pressed(Constants.TRAIN_KEY_KANKANNAVI):
			kankan_on()
		elif not event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(Constants.TRAIN_KEY_KANKANNAVI) and self.visible:
		if _can_open():
			kankan_on()
		else:
			print("Cannot be used because that window is currently open : " + str(GameEvents.get_window_state_array()))
			return

## 칸칸네비를 열 수 있는 상태인지 확인한다.
## 다른 윈도우가 열려있거나 타임라인 재생 중이면 [code]false[/code]를 반환한다.
func _can_open()-> bool:
	if GameEvents.get_window_state_array().size() > 0:
		return false
	elif Dialogic.current_timeline:
		return false
	else:
		return true

## 칸칸네비 맵을 인스턴스화하여 화면에 표시한다.
## 비활성 상태이면 알림을 표시하고 열지 않는다.
func kankan_on():
	is_tuto_blocking = false
	if not is_enable:
		NotionEvent.notion("NOTI_DONT_KANKAN_ON_1", Constants.SD_ICONS[Constants.NPC_BUTLER])
		NotionEvent.notion("NOTI_DONT_KANKAN_ON_2", Constants.LOVE_BRACELET_ICON)

	if not get_current_kankannavi_item() or not is_enable:
		return

	tuto_end.emit()
	var route_map_packed = ResourceLoader.load(ROUTE_MAP) as PackedScene
	var route_map_instance = route_map_packed.instantiate()
	canvas_layer.add_child(route_map_instance)

## Dialogic 시그널 콜백. [code]kankannavi[/code] 이벤트 시 네비를 활성화하고 튜토리얼 블록을 추가한다.
func _on_dialogic_signal(arg: String) -> void:
	match arg:
		"kankannavi":
			navi_on(true)
			is_tuto_blocking = true
			var tuto_block_instance = tuto_block.instantiate() as TutorialBlock
			tuto_end.connect(tuto_block_instance._on_tuto_end)
			add_child(tuto_block_instance)

## 칸칸네비 버튼 표시/숨김을 설정한다. 해금되지 않았으면 항상 숨긴다.
func navi_on(on: bool):
	if not get_current_kankannavi_item():
		hide()
		disabled = true
		return
		
	if on:
		show()
		disabled = false
	else:
		hide()
		disabled = true

## 상점 상태 변경 콜백. 상점이 닫히면 네비를 표시하고, 열리면 숨긴다.
func _on_shop_state_changed(state: int):
	if state == upgrade_manager.ShopState.CLOSE:
		navi_on(true)
	else:
		navi_on(false)

## 새로운 노선 힌트 획득 콜백. 버튼이 보이면 즉시, 숨겨져 있으면 표시 후 바운스 애니메이션을 재생한다.
func _on_get_route_hint():
	if visible == false:
		await visibility_changed
		new_hint_getted()
	else:
		new_hint_getted()

## 힌트 획득 시 버튼 스케일을 바운스 애니메이션으로 강조한다.
func new_hint_getted():
	var base_scale: Vector2 = self.scale
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(self, "scale", base_scale, 0.3)
	tween.tween_callback(emit_highlight)

## 하이라이트 이펙트를 발생시킨다. (현재 미사용)
func emit_highlight():
	pass
	#highlight_shader.start_highlight.emit()

## 칸칸네비 기능이 해금되었는지 확인한다.
## [code]item_navi[/code] 이벤트를 읽었으면 [code]true[/code]를 반환한다.
func get_current_kankannavi_item()-> bool:
	if MetaProgression.has_read_event("item_navi"):
		return true
	return false

## 장착 아이템 업데이트 콜백. 팔찌 착용 여부에 따라 칸칸네비 활성 상태를 갱신한다.
func _on_update_equip_item(_equipment_list: Array[AbilityUpgrade]):
	set_is_disable(get_equip_konial_love_item())

## 칸칸네비 비활성 상태를 설정한다.
## [param state]가 [code]true[/code]이면 비활성화하고 기존 노선·종착점을 모두 해제한다.
func set_is_disable(state: bool):
	if state == false:
		is_enable = true
		self_modulate = Color.WHITE
	else:
		is_enable = false ##칸칸네비 사용 불가
		#기존 노선도 전부 해제
		MetaProgression.clear_setting_routes()
		MetaProgression.clear_kankan_destination()
		setting_route_manager.clear_current_destination()
		setting_route_manager.clear_routes()
		self_modulate = Color.DARK_RED

## 코니알의 사랑의 팔찌를 착용 중인지 확인한다.
func get_equip_konial_love_item()->bool:
	if MetaProgression.has_equipment("love_bracelet"):
		return true
	return false
