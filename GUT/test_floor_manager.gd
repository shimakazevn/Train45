extends GutTest

var manager: FloorManager = FloorManager.new()

func before_each():
	pass

func test_pick_safe_stage_sets_correct_path():
	manager.pick_safe_stage()
	assert_eq(manager.next_stage_path, "res://Gameplay/Levels/stage_safe_0.tscn")

class FakeEventFloorManager:
	var current_love_stage_path = "love_path"

func test_pick_love_stage_sets_path_from_event_manager():
	manager.event_floor_manager = FakeEventFloorManager.new()
	manager.pick_love_stage()
	assert_eq(manager.next_stage_path, "res://Gameplay/Levels/love_path.tscn")


func test_pick_complete_stage_sets_correct_path():
	var current_chapter := 3
	manager.pick_complete_stage(current_chapter)
	assert_eq(manager.next_stage_path, "res://Gameplay/Levels/stage_complete_ep3.tscn")
