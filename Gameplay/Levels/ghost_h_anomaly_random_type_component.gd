extends GhostHAnomaly

## 이상현상에 바리에이션이 있을 경우, 랜덤으로 등장하도록 상속

@export var rand_sprite: Array[CompressedTexture2D]

func set_sprite_random():
	var rand_index: int = randi()%rand_sprite.size()
	ghost_sprite.texture = rand_sprite[rand_index]
