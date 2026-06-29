## 스테이지 클리어 현황 텍스트 UI.
## [br][br]
## 매 프레임 부모 노드의 클리어 수와 이상현상 발견 수를 읽어 화면에 표시한다.
extends CanvasLayer

## 스테이지 클리어 횟수를 표시하는 텍스트 노드.
@onready var clear_text = $Clear_Text
## 발견한 이상현상 수를 표시하는 텍스트 노드.
@onready var anomaly_text = $Anomaly_Text


## 매 프레임 부모 노드의 [code]stage_clear[/code]와 [code]stage_find_anomaly[/code] 값을 반영한다.
func _process(_delta):
	clear_text.text = str(get_parent().stage_clear)
	anomaly_text.text = str(get_parent().stage_find_anomaly)
