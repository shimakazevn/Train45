## UI 요소에 호버(포커스) 시 스케일 및 위치 애니메이션을 적용하는 컴포넌트.
## 부모의 부모 노드([TextureRect])를 대상으로 트윈 애니메이션을 생성한다.
extends Node
class_name AnimationComponent

## [code]true[/code]이면 피벗을 대상 노드 중앙으로 설정한다.
@export var from_center: bool = true
## 호버 시 적용할 스케일 값.
@export var hover_scale: Vector2 = Vector2(1, 1)
## 트윈 애니메이션 지속 시간(초).
@export var time: float = 0.1
## 트윈 전환 타입.
@export var transition_type: Tween.TransitionType
## 호버 효과음을 재생할 [AudioStreamPlayer].
@export var sound_player: AudioStreamPlayer

## 애니메이션이 적용되는 대상 [TextureRect] 노드.
var target: TextureRect
## 포커스 시그널을 수신하는 [Control] 노드.
var signal_target: Control
## 대상 노드의 기본 스케일 값.
var default_scale: Vector2
## 대상 노드의 기본 위치 값.
var default_position: Vector2

## 노드 준비 시 대상과 시그널 소스를 설정하고, 시그널을 연결한다.
func _ready():
	target = get_parent().get_parent()
	signal_target = get_parent()
	setup()
	connect_signals()
	#call_deferred("setup")
	
## [member signal_target]의 포커스 진입/해제 시그널을 연결한다.
func connect_signals():
	signal_target.focus_entered.connect(on_hover)
	signal_target.focus_exited.connect(off_hover)
	
## 트리에서 제거될 때 시그널 연결을 해제한다.
func _exit_tree():
	if !is_instance_valid(signal_target):
		return
	signal_target.focus_entered.disconnect(on_hover)
	signal_target.focus_exited.disconnect(off_hover)
	
## 대상 노드의 피벗, 기본 스케일, 기본 위치를 초기화한다.
func setup():
	if from_center:
		target.pivot_offset = target.size / 2
	default_scale = target.scale
	default_position = target.position  # 초기 위치 저장
	
## 포커스 진입 시 효과음을 재생하고, 스케일 확대 및 X축 이동 트윈을 적용한다.
func on_hover() -> void:
	if sound_player.playing:
		sound_player.stop()
	sound_player.play_random()
	add_tween("scale", hover_scale, time)
	add_tween("position:x", default_position.x + 20, time)  # x축 이동 추가

## 포커스 해제 시 스케일과 위치를 기본값으로 복원하는 트윈을 적용한다.
func off_hover():
	add_tween("scale", default_scale, time)
	add_tween("position:x", default_position.x, time)  # x축 원래 위치로 복귀
	
## 지정된 속성에 트윈 애니메이션을 생성한다.
## [param property]: 트윈할 속성 경로. [param value]: 목표 값. [param seconds]: 지속 시간.
func add_tween(property: String, value, seconds: float):
	if !is_instance_valid(target):
		return
	var tween = create_tween()
	tween.tween_property(target, property, value, seconds).set_trans(transition_type).set_ease(Tween.EASE_OUT)
