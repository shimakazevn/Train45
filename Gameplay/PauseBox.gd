extends Button
## 일시정지 메뉴의 버튼 포커스를 관리하는 [code]Button[/code].
## 포커스 진입/이탈 시 부모 노드의 [member z_index]를 조정하여 시각적 강조를 처리한다.

## 초기화 시 [signal focus_entered]와 [signal focus_exited] 시그널을 연결한다.
func _ready():
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)	
	
## 포커스 진입 시 부모 노드의 [member z_index]를 [code]1[/code]로 설정한다.
func _on_focus_entered():
	get_parent().z_index = 1

## 포커스 이탈 시 부모 노드의 [member z_index]를 [code]0[/code]으로 복원한다.
func _on_focus_exited():
	get_parent().z_index = 0
