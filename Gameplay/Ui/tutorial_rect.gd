extends Polygon2D
class_name Tutorial_Rect

@export var rect : Array[ColorRect] = []
var click_block_rect: Array[ColorRect] = []
@onready var block_rect_container: Control = $BlockRectContainer

@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	set_tuto_rect(0)

func set_tuto_rect(area_num: int):
	if area_num >= rect.size():
		push_warning("해당 area가 배열에 없습니다")
		return

	if rect:
		var rect_position = rect[area_num].position
		var rect_size = rect[area_num].size

		# 사각형 꼭짓점 정의
		var points = [
			rect_position,
			rect_position + Vector2(rect_size.x, 0),
			rect_position + rect_size,
			rect_position + Vector2(0, rect_size.y)
		]

		# Polygon2D에도 반영
		set_polygon(PackedVector2Array(points))

		# 각 점에 트윈으로 이동 애니메이션 부여
		for i in points.size():
			var tween := create_tween()
			tween.tween_method(
				func(p): line_2d.set_point_position(i, p),
				line_2d.points[i],  # 시작 위치
				points[i],          # 목표 위치
				0.4
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		# 원래 ColorRect는 숨김 처리
		rect[area_num].hide()

		# 블록 영역 생성 (클릭 차단)
		create_block_area(rect_position, rect_size)

	else:
		push_warning("rect가 없습니다!")


func create_block_area(rect_position: Vector2, rect_size: Vector2):
	var top_rect = Rect2(Vector2(0,0), Vector2(2000, rect_position.y))
	var bottom_rect = Rect2(
		Vector2(0, rect_position.y+rect_size.y),
		Vector2(2000, 2000 - (rect_position.y + rect_size.y))
	)
	var left_rect = Rect2(Vector2(0, rect_position.y), Vector2(rect_position.x, rect_size.y))
	var right_rect = Rect2(
		Vector2(rect_position.x + rect_size.x, rect_position.y),
		Vector2(2000 - (rect_position.x + rect_size.x), rect_size.y)
	)

	for child in block_rect_container.get_children():
		child.queue_free()
	
	click_block_rect.append(set_block_rect(top_rect))
	click_block_rect.append(set_block_rect(bottom_rect))
	click_block_rect.append(set_block_rect(left_rect))
	click_block_rect.append(set_block_rect(right_rect))
	
func set_block_rect(block_rect: Rect2)->ColorRect:
	var color_rect = ColorRect.new()
	color_rect.position = block_rect.position
	color_rect.size = block_rect.size
	color_rect.color = Color(0, 0, 0, 0.0)
	block_rect_container.add_child(color_rect)
	return color_rect
