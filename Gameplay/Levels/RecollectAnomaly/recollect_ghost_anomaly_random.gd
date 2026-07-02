## [KR] 회상방 전용 랜덤 텍스처 귀신(butt).
## [[recollect_ghost_anomaly]]의 회상방 루프를 그대로 상속하고,
## set_sprite_random만 random_type처럼 재구현해 초기화·리셋 시 텍스처를 재추첨한다.
class_name RecollectGhostHAnomalyRandom
extends RecollectGhostHAnomaly

## [KR] 재추첨 대상 텍스처 후보.
@export var rand_sprite: Array[CompressedTexture2D]

func set_sprite_random() -> void:
	if rand_sprite.is_empty():
		return
	ghost_sprite.texture = rand_sprite[randi() % rand_sprite.size()]
