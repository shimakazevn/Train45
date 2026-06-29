extends CollisionShape2D
class_name OMTMarker

@export var npc_type: Constants.NpcTypes
@export var scene_name: String


@export var h_type: HSfxStream.HSceneTypes = HSfxStream.HSceneTypes.NORMAL

## 이미지가 뜰 방향(체크한 가장자리). 기본값: 좌+우
@export_flags("좌", "우", "상", "하") var spawn_sides := 3
