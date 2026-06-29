extends Resource
class_name HSceneRes

##현재 게임내에 추가 안된 씬의 경우 체크
@export var is_disabled:= false

##다음 호감도로 상승하기 전에 감상해야 하는 이벤트일 경우 체크합니다
@export var main_love_event:= false
@export var scene_description: String = ""
@export var scene_name: String = ""
@export var dialog_title := ""
@export var stage_name:= ""
@export_enum("Reina", "Mai", "Konial", "Pazuzu", "Butler") var partner: int
@export_range(0, 10) var love_ability: int = 0
@export var preview_texture: CompressedTexture2D
##위치 설정용 더미 데이터는 stage_recollection_room 씬에 있음
@export var is_position: Vector2 = Vector2.ZERO
@export var unlock_chapter: int = 0
@export var ahen_keys: PackedStringArray = PackedStringArray()
