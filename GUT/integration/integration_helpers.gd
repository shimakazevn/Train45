## 통합 테스트용 헬퍼. 게임 본문은 수정하지 않고 오토로드 공개 API만 사용한다.
## 테스트 스크립트에서 [code]const IntegrationHelpers = preload(...)[/code] 후 정적 호출한다.
extends RefCounted

## user:// 세이브와 겹치지 않게 높은 슬롯을 사용한다.
const INTEGRATION_SAVE_SLOT := 19


static func save_path_for_slot(slot: int) -> String:
	return MetaProgression.SAVE_FILE_PATH + MetaProgression.SAVE_FILE_NAME + str(slot) + MetaProgression.SAVE_FILE_TYPE


static func remove_save_slot(slot: int) -> void:
	var dir := DirAccess.open(MetaProgression.SAVE_FILE_PATH)
	if dir == null:
		return
	var fname: String = MetaProgression.SAVE_FILE_NAME + str(slot) + MetaProgression.SAVE_FILE_TYPE
	if dir.file_exists(fname):
		dir.remove(fname)


static func clear_integration_save_slot() -> void:
	remove_save_slot(INTEGRATION_SAVE_SLOT)


## 디스크에 비어 있지 않은 세이브를 쓴다. [method MetaProgression.has_anyone_save_data] 등이 참이 되도록 한다.
static func seed_nonempty_save(slot: int = INTEGRATION_SAVE_SLOT) -> void:
	MetaProgression.save_slot = slot
	MetaProgression.new_game()
	MetaProgression.save_data["last_save_date"] = Time.get_datetime_dict_from_system()
	MetaProgression.save_data["last_save_date"]["unix_time"] = Time.get_unix_time_from_system()
	MetaProgression.game_save(slot)


## 회상방 해금 판정([method MetaProgression.is_unlock_recollect])용으로 [code]is_ending[/code]을 켠다.
static func seed_ending_cleared_save(slot: int = INTEGRATION_SAVE_SLOT) -> void:
	MetaProgression.save_slot = slot
	MetaProgression.new_game()
	MetaProgression.save_data["is_ending"] = true
	MetaProgression.save_data["last_save_date"] = Time.get_datetime_dict_from_system()
	MetaProgression.save_data["last_save_date"]["unix_time"] = Time.get_unix_time_from_system()
	MetaProgression.game_save(slot)


static func reset_game_events_for_title() -> void:
	GameEvents.is_recollection_room = false
	GameEvents.is_epilogue_room = false
