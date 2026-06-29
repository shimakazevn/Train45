## 열차 배경의 기본 구성을 관리하는 노드.
## 열차 스프라이트, 조명, 진동 시그널 등을 포함한다.
extends Node2D
class_name TrainBackGround

## 열차 진동 이벤트 발생 시 방출되는 시그널.
signal train_vibe

## 열차 외관을 표시하는 [Sprite2D] 노드.
@export var train_sprite : Sprite2D
## 씬 전체 조명을 담당하는 [DirectionalLight2D] 노드.
@onready var globalLight = $DirectionalLight2D

## [signal train_vibe] 시그널을 방출하여 열차 진동 이벤트를 알린다.
func train_vibe_emit():
	train_vibe.emit()
