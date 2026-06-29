extends GutTest

const IntegrationHelpers = preload("res://GUT/integration/integration_helpers.gd")
const GAMEPLAY_SCENE := preload("res://Gameplay/gameplay.tscn")


func before_each() -> void:
	IntegrationHelpers.clear_integration_save_slot()
	MetaProgression.new_game()
	IntegrationHelpers.reset_game_events_for_title()


func after_each() -> void:
	IntegrationHelpers.reset_game_events_for_title()


func test_new_game_mounts_prologue_level() -> void:
	assert_true(MetaProgression.is_new_game())
	var gp: Gameplay = GAMEPLAY_SCENE.instantiate() as Gameplay
	add_child_autofree(gp)
	await wait_frames(15, "gameplay _ready init_level")
	assert_not_null(gp.current_level, "신규 게임이면 current_level이 있어야 함")
	assert_true(gp.current_level.prologue_stage, "프롤로그 스테이지여야 함")


func test_continue_flow_uses_existing_level_holder_child() -> void:
	MetaProgression.save_data["last_save_date"] = {"unix_time": 1.0}
	assert_false(MetaProgression.is_new_game())
	var gp: Gameplay = GAMEPLAY_SCENE.instantiate() as Gameplay
	add_child_autofree(gp)
	await wait_frames(10, "gameplay _ready load_saved")
	assert_not_null(gp.current_level)
	assert_eq(gp.current_level.stage_type, Constants.TYPE_BASE, "이어하기는 씬에 깔린 베이스 레벨을 사용")
