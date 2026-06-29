## 라이프 볼 아이콘 스프라이트 애니메이션 컴포넌트.
## [br][br]
## [member textures] 배열의 텍스처를 순서대로 교체하여 프레임 기반 애니메이션을 재생한다.
## 시작 프레임과 재생 속도에 미세한 랜덤 변동을 주어 각 인스턴스가 자연스럽게 다르게 보인다.
extends TextureRect

## 애니메이션에 사용할 텍스처 프레임 배열.
@export var textures: Array[CompressedTexture2D]

## 현재 재생 중인 프레임 인덱스.
var current_frame := 0
## 프레임 전환 기준 시간(초). 실제 속도는 ±10% 랜덤 보정된다.
@export var base_frame_time := 0.1  # 기준 재생 속도 (기본 0.1초)
## 랜덤 보정이 적용된 실제 프레임 전환 시간.
var frame_time := 0.1  # 실제 재생 속도 (살짝 랜덤)
## 현재 프레임 내 경과 시간 누적값.
var elapsed_time := 0.0

## 랜덤 시작 프레임과 재생 속도 보정을 적용하여 초기화한다.
func _ready():
	if not textures.is_empty():
		current_frame = randi() % textures.size()
		self.texture = textures[current_frame]
		
		# 재생 속도를 미묘하게 랜덤 조정 (±10% 정도)
		var random_factor = randf_range(0.9, 1.1)
		frame_time = base_frame_time * random_factor

## [member frame_time] 간격으로 다음 프레임 텍스처로 전환한다.
func _process(delta):
	if textures.is_empty():
		return
	
	elapsed_time += delta
	if elapsed_time >= frame_time:
		elapsed_time = 0.0
		current_frame = (current_frame + 1) % textures.size()
		self.texture = textures[current_frame]
