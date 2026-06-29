## 알림(Notion) 큐 관리자.
## [signal NotionEvent.notion_call] 시그널을 수신하여 알림 박스를 큐에 쌓고,
## 쿨타임 타이머를 통해 순차적으로 화면에 표시한다.
extends CanvasLayer

## 알림 박스 [PackedScene] 템플릿.
@export var notion : PackedScene
## 알림 박스가 추가되는 컨테이너 노드.
@onready var notion_container = $NotionContainer
## 알림 팝아웃 쿨타임 타이머.
@onready var timer = $Timer
## 팝아웃 대기 중인 알림 인스턴스 큐.
var notion_list : Array[Control] = []

## 화면에 동시 표시 가능한 최대 알림 수.
const MAX_NOTI: int = 9

## 시그널 연결을 수행한다.
func _ready():
	NotionEvent.notion_call.connect(on_notion_call)
	timer.timeout.connect(_on_timeout)  # 타이머의 timeout 신호 연결

## 매 프레임 컨테이너에 자식이 있으면 완료된 알림 정리를 시도한다.
func _process(_delta):
	if notion_container.get_child_count() > 0:
		clear_finished_notion_if_all_finished()

## 새로운 알림을 큐에 추가한다.
## [param _str]은 알림 텍스트, [param texture]는 아이콘, [param color]는 텍스트 색상이다.
## 타이머가 정지 상태이면 쿨타임을 시작하여 팝아웃을 트리거한다.
# 새로운 노션을 리스트에 추가하고 쿨타임이 끝나면 popout 호출
func on_notion_call(_str: String, texture: CompressedTexture2D = null, color:Color = Color.WHITE):
	var notion_instante = notion.instantiate()
	notion_list.append(notion_instante)
	notion_instante.notion_string(_str, texture, color)
	
	
	# 타이머가 작동하지 않는 상태라면, 쿨타임을 시작하여 첫 popout 호출
	if not timer.is_stopped():
		return  # 타이머가 작동 중이라면 바로 리턴
	timer.start(0.3)  # 1초 쿨타임 시작

## 타이머 타임아웃 콜백. 큐에 알림이 남아있으면 팝아웃하고, 비어있으면 타이머를 정지한다.
# 쿨타임이 종료될 때마다 노션을 추가하고 리스트가 비어있으면 타이머 정지
func _on_timeout():
	if notion_list.size() > 0:
		notion_instant_popout()  # 리스트에서 popout 추가
	else:
		timer.stop()  # 리스트가 비어있으면 타이머 정지

## 큐에서 알림을 꺼내 [member notion_container]에 추가한다.
## [member MAX_NOTI]를 초과하면 가장 오래된 알림을 제거한다.
# 노션을 notion_container에 추가하는 함수
func notion_instant_popout():
	var n = notion_list.pop_front()
	notion_container.add_child(n)
	notion_container.move_child(n,0)
	if notion_container.get_children().size() >= MAX_NOTI:
		var noti: NotionBox = notion_container.get_child(MAX_NOTI-1)
		#noti.noti_exit()
		noti.queue_free()


## 컨테이너 내 모든 알림의 [member anim_fin]이 [code]true[/code]이면 일괄 제거한다.
# 모든 자식 노드가 anim_fin 상태일 때만 제거
func clear_finished_notion_if_all_finished():
	var all_finished = true
	
	# 모든 노드가 anim_fin 상태인지 확인
	for n in notion_container.get_children():
		if not n.anim_fin:
			all_finished = false
			break  # anim_fin이 아닌 노드가 하나라도 있으면 반복 중지

	# 모든 노드가 anim_fin 상태인 경우 제거
	if all_finished:
		for n in notion_container.get_children():
			n.queue_free()
