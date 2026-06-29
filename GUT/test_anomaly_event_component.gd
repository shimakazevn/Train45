extends GutTest

var anomaly_event: EventArea = EventArea.new()

func before_each():
	anomaly_event.partner_manager = PartnerManager.new()
	anomaly_event.partner_manager.partner = [
		preload("res://Gameplay/NPC/ol.tscn").instantiate(),
		preload("res://Gameplay/NPC/gyaru.tscn").instantiate(),
		preload("res://Gameplay/NPC/konial.tscn").instantiate(),
		preload("res://Gameplay/NPC/pazuzu.tscn").instantiate(),
		preload("res://Gameplay/NPC/butler.tscn").instantiate()
	]
	anomaly_event.floor_manager = FloorManager.new()
	anomaly_event.h_scene_info = HSceneRes.new()
	# EventArea는 씬의 HEventBubble 등 @onready 노드를 쓴다. 트리에 넣지 않은 단위 테스트용으로 직접 채운다.
	anomaly_event.h_event_bubble = TextureRect.new()
	anomaly_event.love_level_fill = TextureRect.new()

func test_event_enabled_update():
	# 시작 지점에 h이벤트가 있을 경우, 해당 엔피씨가 조건이 만족하면 이벤트 말풍선을 표시한다.
	anomaly_event.floor_manager.current_stage_type = Constants.TYPE_BASE
	anomaly_event.h_scene_info.partner = Constants.NPC_BUTLER
	anomaly_event.h_scene_info.love_ability = 2
	
	anomaly_event.partner_manager.partner[Constants.NPC_BUTLER].love_level = 4
	anomaly_event.event_bubble_update(anomaly_event.partner_manager)
	
	assert_eq(anomaly_event.event_enabled, true, "이벤트 로직 오류") 
	assert_eq(anomaly_event.modulate, anomaly_event.original_color, "말풍선 컬러 반영 안됨")
	
	anomaly_event.partner_manager.partner[Constants.NPC_BUTLER].love_level = 1
	anomaly_event.event_bubble_update(anomaly_event.partner_manager)
	
	assert_eq(anomaly_event.event_enabled, false, "이벤트 로직 오류") 
	assert_eq(anomaly_event.modulate, anomaly_event.disabled_color, "말풍선 컬러 반영 안됨")
	
	# 스테이지나 종착점의 경우 동행중인 엔피씨일 경우에만 말풍선을 활성화한다
