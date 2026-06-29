## [KR] 플레이어 주변의 드롭 아이템을 자동으로 수집하는 영역.
## [EN] Area that automatically collects dropped items around the player.
## [KR] 영역에 진입한 [DropItem]에 대해 [method DropItem.set_pick]을 호출하여
## [KR] 플레이어 방향으로 아이템을 끌어당긴다.
## [EN] Calls [method DropItem.set_pick] on [DropItem]s that enter the area to pull items toward the player.
extends Area2D

## [KR] 수집된 아이템 배열
## [EN] Array of collected items.
var items: Array
## [KR] 수집 영역의 충돌 셰이프 노드
## [EN] Collision shape node for the collect area.
@onready var item_collect_collision: CollisionShape2D = $ItemCollectCollision

## [KR] [DropItem]이 영역에 진입하면 해당 아이템의 수집 처리를 시작한다.
## [EN] When a [DropItem] enters the area, starts the collection process for that item.
func _on_area_entered(area: Area2D) -> void:
	if area.owner is DropItem:
		area.owner.set_pick(owner)

## [KR] 수집 영역의 충돌 셰이프 크기를 [param size]로 설정한다.
## [EN] Sets the collect area's collision shape size to [param size].
func set_collect_area(size: Vector2):
	item_collect_collision.shape.size = size
