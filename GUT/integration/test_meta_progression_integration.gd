extends GutTest

const IntegrationHelpers = preload("res://GUT/integration/integration_helpers.gd")


func before_each() -> void:
	IntegrationHelpers.clear_integration_save_slot()


func after_each() -> void:
	IntegrationHelpers.clear_integration_save_slot()


func test_game_save_and_load_roundtrip_restores_chapter() -> void:
	var slot: int = IntegrationHelpers.INTEGRATION_SAVE_SLOT
	MetaProgression.save_slot = slot
	MetaProgression.new_game()
	MetaProgression.save_data["chapter"] = 4
	MetaProgression.save_data["ticket_num"] = 42
	MetaProgression.game_save(slot)

	MetaProgression.new_game()
	assert_eq(MetaProgression.save_data.get("chapter", -1), 0, "new_game 후 기본 챕터")

	MetaProgression.load_save_file(slot)
	assert_eq(MetaProgression.save_data["chapter"], 4)
	assert_eq(MetaProgression.save_data["ticket_num"], 42)


func test_is_new_game_false_after_save() -> void:
	var slot: int = IntegrationHelpers.INTEGRATION_SAVE_SLOT
	MetaProgression.save_slot = slot
	MetaProgression.new_game()
	assert_true(MetaProgression.is_new_game())
	MetaProgression.game_save(slot)
	assert_false(MetaProgression.is_new_game())
