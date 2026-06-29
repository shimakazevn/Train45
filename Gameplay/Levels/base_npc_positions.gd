extends Node2D

@export var positions: Array[Marker2D]
@export var npcs: Array[Npc]

func _ready() -> void:
	GameEvents.stage_change.connect(_on_stage_change)

func _on_stage_change():
	if npcs.size() > positions.size():
		push_warning("NPC 수가 마커 수보다 많습니다. 일부 위치는 중복됩니다.")
	
	var index_pool := []
	for i in positions.size():
		index_pool.append(i)
	index_pool.shuffle()

	for i in npcs.size():
		var rand_index :int = index_pool[i % index_pool.size()]  # NPC가 마커 수보다 많을 경우 재사용
		var rand_pos_offset: Vector2 = Vector2(0.0, randf_range(0.0, 45.0))
		npcs[i].position = positions[rand_index].global_position - rand_pos_offset
		npcs[i].set_flip(randi() % 2 == 0)
