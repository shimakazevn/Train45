extends GutTest

const IntegrationHelpers = preload("res://GUT/integration/integration_helpers.gd")
const GAMEPLAY_SCENE := preload("res://Gameplay/gameplay.tscn")
const STAGE_SAFE := "res://Gameplay/Levels/stage_safe_0.tscn"


func before_each() -> void:
	IntegrationHelpers.clear_integration_save_slot()
	MetaProgression.new_game()
	MetaProgression.save_data["last_save_date"] = {"unix_time": 1.0}
	IntegrationHelpers.reset_game_events_for_title()


func after_each() -> void:
	IntegrationHelpers.reset_game_events_for_title()


func test_swap_scenes_loads_into_level_holder_and_signals_complete() -> void:
	var gp: Gameplay = GAMEPLAY_SCENE.instantiate() as Gameplay
	add_child_autofree(gp)
	await wait_frames(10, "gameplay ready with base level")
	var outgoing: Level = gp.current_level
	assert_not_null(outgoing)

	SceneManager.swap_scenes(STAGE_SAFE, gp.level_holder, outgoing, "no_transition")

	var ok: bool = await wait_for_signal(SceneManager.load_complete, 120.0, "SceneManager.load_complete")
	assert_true(ok, "load_complete가 제한 시간 내 발생해야 함")
	var loaded: Level = gp.current_level
	assert_not_null(loaded)
	assert_true(loaded is Level, "current_level은 Level이어야 함")
	assert_true(
		loaded.scene_file_path.contains("stage_safe_0"),
		"stage_safe_0 경로여야 함: %s" % loaded.scene_file_path
	)

	# stage_safe_0은 기지 레벨이 넘긴 핸드오프 데이터를 처리하지 않아 push_warning을 남긴다.
	# 이는 SceneManager 설계상 의도된 동작이므로(level.gd receive_data 참조)
	# 해당 경고만 handled 처리하여 "Unexpected Errors" 실패에서 제외한다.
	for err in get_errors():
		if err.contains_text("is receiving data it cannot process"):
			err.handled = true
