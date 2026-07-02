## [KR] 회상방 귀신 도감 상호작용 오브젝트(TrainStandard/Ghosts).
## - 플레이어가 근처에 오면 아웃라인 강조(item_box 방식) + KeyboardIcon 표시, 멀어지면 끈다.
## - action(스페이스) 입력 시 도감 창을 연다(내용은 GhostData 리소스 기반 — 추후 구현).
extends Sprite2D

## [KR] 근접 시 플레이어 TalkArea를 감지하는 영역.
@onready var detect_area: Area2D = get_node_or_null("Area2D")
## [KR] 근접 시 표시할 입력 안내 아이콘.
@onready var keyboard_icon: CanvasItem = get_node_or_null("KeyboardIcon")
## [KR] 스페이스 입력 시 열 귀신 도감 창.
@export var gallery_window: GhostGalleryWindow

## [KR] 아웃라인 셰이더의 기본 width(켤 때 값). _ready에서 머티리얼로부터 읽어둔다.
var base_width: float = 0.0
var current_near_player: bool = false

func _ready() -> void:
	if material:
		base_width = material.get_shader_parameter("width")
	if detect_area:
		detect_area.area_entered.connect(_on_area_entered)
		detect_area.area_exited.connect(_on_area_exited)
	near_player(false)

## [KR] 근접 상태에 따라 아웃라인 width와 KeyboardIcon 표시를 토글한다.
func near_player(is_near: bool) -> void:
	current_near_player = is_near
	if material:
		material.set_shader_parameter("width", base_width if is_near else 0.0)
	if keyboard_icon:
		keyboard_icon.visible = is_near

func _on_area_entered(area: Area2D) -> void:
	if area is TalkArea:
		near_player(true)

func _on_area_exited(area: Area2D) -> void:
	if area is TalkArea:
		near_player(false)

func _input(event: InputEvent) -> void:
	# 도감 창이 열려 있는 동안엔 도감 오브젝트 입력을 받지 않는다(창이 처리).
	if gallery_window and gallery_window.is_open:
		return
	if not current_near_player:
		return
	if event.is_action_pressed("action"):
		# 대화/이벤트 중에는 무시(스페이스 입력 충돌 방지).
		if GameEvents.game_state == Constants.STATE_EVENT or Dialogic.current_timeline:
			return
		_open_gallery()
		# 같은 입력이 방금 포커스된 창 버튼까지 전달돼 즉시 선택되는 것 방지.
		get_viewport().set_input_as_handled()

## [KR] 귀신 도감 창 열기. 창 내용은 res://Gameplay/GameData/GhostData/ 의 GhostRes 리소스로 구성 예정.
func _open_gallery() -> void:
	if gallery_window:
		gallery_window.open(self)
