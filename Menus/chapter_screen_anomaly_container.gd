extends GridContainer

##이변 칸 ui전부 나온 후 다음 이변 추가 아이콘 등장시키기 위해 사용하는 시그널
signal before_end

@export var is_owner: ChapterScreen
@export var anomaly_icon: PackedScene

@onready var anomaly_info_lable: Label = %AnomalyInfoLable
@onready var anomaly_lable: Label = %AnomalyLable
@onready var new_anomaly_lable: Label = %NewAnomalyLable


var route_data: RouteData
var next_chapter_routes: Dictionary = {}

func _ready() -> void:
	route_data = RouteData.new()
	if Constants.CHAPTER_SCREEN_DEBUG:
		next_chapter_routes = route_data.get_current_chapter_route(is_owner.debug_test_next_chapter)
	else:
		next_chapter_routes = route_data.get_current_chapter_route(is_owner.next_chapter)
	
	anomaly_info_lable.modulate = Color.TRANSPARENT
	anomaly_lable.modulate = Color.TRANSPARENT
	new_anomaly_lable.modulate = Color.TRANSPARENT
	
	## init_clear_child
	for i in get_children():
		i.queue_free()

func start_anomaly_info():
	is_owner.chapter_player.speed_scale = 0.0
	
	anomaly_info_lable.modulate = Color.WHITE
	anomaly_lable.modulate = Color.WHITE
	await get_tree().create_timer(1.0).timeout
	# 1단계: 이전 챕터들 (미만)
	append_anomaly_icons(is_owner.next_chapter, true)
	await before_end
	await get_tree().create_timer(1.0).timeout
	# 2단계: 현재 챕터만
	new_anomaly_lable.modulate = Color.WHITE
	await get_tree().create_timer(1.0).timeout
	append_anomaly_icons(is_owner.next_chapter, false)

func append_anomaly_icons(chapter: int, is_before: bool):
	if Constants.CHAPTER_SCREEN_ANOMALY_SFX_DEBUG:
		await append_anomaly_icons_debug(is_before)
		return

	var find_anomaly_count:= 0

	for i in next_chapter_routes:
		var route_chapter = next_chapter_routes[i]["chapter"]
		
		if is_before:
			if route_chapter >= chapter:
				continue
		else:
			if route_chapter != chapter:
				continue

		var anomaly_icon_instance = anomaly_icon.instantiate() as ChapterAnomalyIcon
		add_child(anomaly_icon_instance)
		

		if is_before:
			if MetaProgression.has_route_data(i):
				anomaly_icon_instance.set_state(ChapterAnomalyIcon.State.FIND)
				find_anomaly_count += 1
				anomaly_lable.text = str(find_anomaly_count)
			else:
				anomaly_icon_instance.set_state(ChapterAnomalyIcon.State.UNFIND)

		else:
			anomaly_icon_instance.set_state(ChapterAnomalyIcon.State.NEW)


		
		await get_tree().create_timer(0.1).timeout
	if !is_before:
		is_owner.chapter_player.speed_scale = 1.0
	else:
		call_deferred("emit_before_end")
		

func emit_before_end():
	before_end.emit()

## 디버그용: 루트 데이터를 무시하고 FIND·UNFIND·NEW 아이콘을 고정 개수만큼 생성해 효과음을 확인한다.
func append_anomaly_icons_debug(is_before: bool):
	var count: int = Constants.CHAPTER_SCREEN_ANOMALY_SFX_DEBUG_COUNT
	if is_before:
		# FIND 고정 개수
		var find_anomaly_count:= 0
		for n in count:
			var icon = anomaly_icon.instantiate() as ChapterAnomalyIcon
			add_child(icon)
			icon.set_state(ChapterAnomalyIcon.State.FIND)
			find_anomaly_count += 1
			anomaly_lable.text = str(find_anomaly_count)
			await get_tree().create_timer(0.1).timeout
		# UNFIND 고정 개수
		for n in count:
			var icon = anomaly_icon.instantiate() as ChapterAnomalyIcon
			add_child(icon)
			icon.set_state(ChapterAnomalyIcon.State.UNFIND)
			await get_tree().create_timer(0.1).timeout
		call_deferred("emit_before_end")
	else:
		# NEW 고정 개수
		for n in count:
			var icon = anomaly_icon.instantiate() as ChapterAnomalyIcon
			add_child(icon)
			icon.set_state(ChapterAnomalyIcon.State.NEW)
			await get_tree().create_timer(0.1).timeout
		is_owner.chapter_player.speed_scale = 1.0
