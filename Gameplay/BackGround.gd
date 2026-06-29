## 배경 스크롤 및 페이드 인/아웃 애니메이션을 처리하는 노드.
## 매 프레임마다 왼쪽으로 이동하며, 페이드 인/아웃 순환 애니메이션을 재생한다.
extends Node2D


## [AnimationPlayer] 노드 참조. 페이드 인/아웃 애니메이션 재생에 사용된다.
@onready var animation_player = $CanvasLayer/AnimationPlayer

## 노드 준비 시 페이드 인 애니메이션을 재생하고, 애니메이션 종료 시그널을 연결한다.
func _ready():
	animation_player.play("fade_in")
	animation_player.animation_finished.connect(on_finished_anim)

## 매 프레임 배경을 왼쪽으로 스크롤한다.
func _process(delta):
	position.x -= 3.0 * delta
	pass

## 위치를 무작위 X 좌표로 초기화한다.
func rand_position():
	position.x = randf_range(-1080.0, 0.0)


## 애니메이션 종료 시 호출되는 콜백. 페이드 인/아웃을 순환 재생한다.
## [param anim_name]이 [code]"fade_in"[/code]이면 위치를 초기화 후 페이드 아웃을,
## [code]"fade_out"[/code]이면 페이드 인을 재생한다.
func on_finished_anim(anim_name:String):
	if anim_name == "fade_in":
		rand_position()
		animation_player.play("fade_out")
	elif anim_name == "fade_out":
		animation_player.play("fade_in")
	
