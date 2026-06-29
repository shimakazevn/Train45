## 개발자 모드 치트 버튼. 각 버튼에 고유 치트 이름을 할당하여 [code]DevModManager[/code]에서 처리한다.
extends Button
class_name DevModeButton

## 이 버튼이 실행할 치트 명령의 식별 이름.
@export var cheat_name: String
