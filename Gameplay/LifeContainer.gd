extends HBoxContainer
## 라이프 볼 UI를 관리하는 컨테이너.
## [GlobalGameManager]의 생명 값 변경에 반응하여 라이프 볼 인스턴스를 업데이트한다.

## 라이프 볼로 인스턴스화할 [PackedScene]
@export var life_ball : PackedScene
## [GlobalGameManager] 참조
var global_game_manager : GlobalGameManager

## 초기화 시 [GlobalGameManager]를 찾고 [signal life_changed] 시그널을 연결한 후 UI를 구성한다.
func _ready():
	global_game_manager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	global_game_manager.life_changed.connect(on_life_changed)

	# 초기 life_base 값으로 UI 구성
	update_life_balls()

## [signal life_changed] 시그널의 콜백. [method update_life_balls]를 호출하여 UI를 갱신한다.
# 생명 값이 변경될 때 호출되는 함수
func on_life_changed():
	update_life_balls()

## 전체 라이프 볼 UI를 업데이트한다.
## 기존 자식 노드를 모두 제거한 후, 현재 생명 값에 맞게 [member life_ball]을 다시 추가한다.
# 전체 life_ball UI를 업데이트하는 함수
func update_life_balls():
	# 기존 life_ball들을 모두 제거
	for child in get_children():
		child.queue_free()

	# 새로운 life_base 값에 맞게 life_ball을 다시 추가
	for life in global_game_manager.life:
		var life_ball_instante = life_ball.instantiate()
		add_child(life_ball_instante)
