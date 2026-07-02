## [KR] 귀신 도감 버튼. GhostRes 하나를 미리보기 이미지 + 텍스트로 표시한다.
## 누르면 selected 시그널로 해당 GhostRes를 알린다.
extends Button
class_name GhostGalleryButton

signal selected(ghost_res: GhostRes)

@onready var preview: TextureRect = $Preview
@onready var stage_name_label: Label = %StageNameLabel

var ghost_res: GhostRes

func _ready() -> void:
	pressed.connect(func(): selected.emit(ghost_res))
	_apply()

## [KR] 표시할 GhostRes를 지정한다(_ready 전/후 모두 안전).
func setup(res: GhostRes) -> void:
	ghost_res = res
	if is_node_ready():
		_apply()

func _apply() -> void:
	if ghost_res == null:
		return
	preview.texture = ghost_res.preview_img # 추후 채울 예정(없으면 비어 보임)
	# stage_name("stage_13")에 해당하는 스테이지 title 번역키를 라벨에 넣는다(라벨 자동 번역).
	stage_name_label.text = _get_stage_title_key(ghost_res.stage_name)

## [KR] stage_name으로 route_data에서 해당 스테이지의 title 번역키를 찾는다(없으면 stage_name).
func _get_stage_title_key(sname: String) -> String:
	var fm = get_tree().get_first_node_in_group("floormanager")
	if fm:
		var key: String = fm.route_data.get_route_title_routename(sname, "name")
		if key != "":
			return key
	return sname
