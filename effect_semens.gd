## 정액 이펙트 스프라이트.
## 랜덤 딜레이 후 랜덤 프레임과 좌우 반전을 적용하여 스케일 트윈으로 등장한다.
extends Sprite2D

## 등장 트윈 참조.
var tween:Tween

## 초기화 — 스케일을 0으로 설정 후 랜덤 딜레이를 거쳐 등장 트윈을 재생한다.
func _ready() -> void:
	scale = Vector2.ZERO
	await get_tree().create_timer(randf_range(1.0, 5.0)).timeout
	
	frame = randi() % hframes
	flip_h = randi() % 2
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).from(Vector2(0.3,0.3)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
