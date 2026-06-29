## 열차 내부 전광판(스크린)을 제어하는 노드.
## 현재 층수에 맞는 애니메이션을 표시하며, 스테이지 진행/클리어 상태를 반영한다.
extends Node2D

## 층 관리 노드 참조. [code]"floormanager"[/code] 그룹에서 가져온다.
var floormanager
## 스테이지 핸들러 참조.
var stage_handler
## 전광판 애니메이션을 재생하는 [AnimationPlayer].
@onready var animation_player = $AnimationPlayer
## 전광판 스프라이트.
@onready var sprite_2d = $Sprite2D

## 스테이지 진행 중 여부.
var run_stage := false

## 노드 준비 시 현재 층수에 해당하는 애니메이션을 재생하고, 스테이지 이벤트 시그널을 연결한다.
func _ready():
	floormanager = get_tree().get_first_node_in_group("floormanager")
	if floormanager == null:
		#printerr("현재 층수 null")
		animation_player.play("1")
		return
	else:
		animation_player.play(str(floormanager.current_floor))
	
	GameEvents.stage_run.connect(_on_stage_run)
	GameEvents.stage_clear.connect(_on_stage_clear)
	

## 스테이지 클리어 시 [code]"clear"[/code] 애니메이션을 재생한다.
func _on_stage_clear():
	animation_player.play("clear")

## 스테이지 진행 상태 변경 시 호출된다. [member run_stage]를 갱신하고 [code]"run"[/code] 애니메이션을 재생한다.
func _on_stage_run(run:bool):
	run_stage = run
	animation_player.play("run")
