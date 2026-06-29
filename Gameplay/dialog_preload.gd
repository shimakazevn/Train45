extends Node
## 대화 캐릭터 리소스를 미리 로드하는 상수 노드.
## 게임에서 사용되는 캐릭터별 대화 리소스를 [code]preload[/code]로 캐싱한다.

## 코니알 캐릭터 리소스
const KONIAL = preload("uid://bvniu0kmofvp0")
## 마이 캐릭터 리소스
const MAI = preload("uid://tw403pgf8np6")
## 파주주 캐릭터 리소스
const PAZUZU = preload("uid://b27qlbgw3yg2s")
## 레이나 캐릭터 리소스
const REINA = preload("uid://ctxfns5n75icl")

## 초기화 콜백. 현재 사용되지 않음.
func _ready() -> void:
	#Dialogic.preload_timeline("res://Gameplay/Dialog/TimeLines/basetalk.dtl")
	pass
