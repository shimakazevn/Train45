## [KR] 메타 프로그레션 시스템 (세이브/로드 관리자).
## [br]게임의 세이브 데이터를 관리하는 오토로드 싱글턴.
## [member save_data] 딕셔너리를 통해 모든 게임 진행 상태를 추적하며,
## [code]user://game{슬롯번호}.save[/code] 경로에 파일로 저장/로드한다.
## [br]리전별로 기능이 분류됨: META_SYSTEM, ABILITY, TICKET, NPC, READ_EVENT,
## GAME_STATE, ROUTE, ROUTE_HINT, CURRENCY_ITEM, ITEM_BOX.
## [EN] Meta progression system (save/load manager).
## [br]Autoload singleton that manages game save data.
## Tracks all game progress via [member save_data] dictionary,
## and saves/loads to file at [code]user://game{slot_number}.save[/code] path.
## [br]Features organized by region: META_SYSTEM, ABILITY, TICKET, NPC, READ_EVENT,
## GAME_STATE, ROUTE, ROUTE_HINT, CURRENCY_ITEM, ITEM_BOX.
extends Node

## [KR] 테스터 식별용 고유 ID. 세이브 데이터의 [code]tester_id[/code] 키에 기록된다.
## [EN] Unique ID for tester identification. Recorded in the [code]tester_id[/code] key of save data.
const TESTER: String = "L6P4-XNQ7-A9F2"

## [KR] 세이브 파일이 저장되는 기본 경로. [code]user://[/code] 디렉토리를 사용한다.
## [EN] Default path where save files are stored. Uses the [code]user://[/code] directory.
const SAVE_FILE_PATH = "user://"
## [KR] 세이브 파일명 접두사. 슬롯 번호와 결합되어 [code]game0[/code], [code]game1[/code] 등이 된다.
## [EN] Save file name prefix. Combined with slot number to form [code]game0[/code], [code]game1[/code], etc.
const SAVE_FILE_NAME = "game"
## [KR] 세이브 파일 확장자.
## [EN] Save file extension.
const SAVE_FILE_TYPE = ".save"
## [KR] 최대 세이브 슬롯 수. 회상방 해금 판정 등 전체 슬롯 순회 시 이 값을 기준으로 한다.
## [EN] Maximum number of save slots. Used as the limit when iterating all slots for recollection room unlock checks, etc.
const SAVE_SLOT_MAX = 50

## [KR] 현재 선택된 세이브 슬롯 번호.
## [EN] Currently selected save slot number.
var save_slot := 0

## [KR] 루트 힌트가 추가되었을 때 발신되는 시그널. UI 갱신에 사용된다.
## [EN] Signal emitted when a route hint is added. Used for UI updates.
signal get_route_hint
## [KR] 스테이지를 최초로 클리어했을 때 발신되는 시그널.
## [EN] Signal emitted when a stage is cleared for the first time.
signal stage_first_clear
## [KR] 스토리 엔딩에 도달했을 때 발신되는 시그널. (도전과제용)
signal ending_reached
## [KR] H/회상 이벤트가 신규 해금될 때 발신되는 시그널. (도전과제용)
signal event_unlocked(npc_type: int, event_name: String)
## [KR] 종착점에 도달해 방문 정보가 기록될 때 발신되는 시그널. (도전과제용)
signal destination_cleared

## [KR] 신규 게임의 세이브 데이터 기본 템플릿.
## [br]모든 세이브 키의 초기값을 정의하며, [method new_game] 및 [method ensure_default_fields]에서 참조된다.
## 주요 키: [code]chapter[/code], [code]ticket_num[/code], [code]npc_info[/code],
## [code]read_event[/code], [code]route_data[/code], [code]ability[/code], [code]equipment[/code] 등.
## [EN] Default template for new game save data.
## [br]Defines initial values for all save keys, referenced by [method new_game] and [method ensure_default_fields].
## Key fields: [code]chapter[/code], [code]ticket_num[/code], [code]npc_info[/code],
## [code]read_event[/code], [code]route_data[/code], [code]ability[/code], [code]equipment[/code], etc.
const DEFAULT_SAVE_DATA: Dictionary = {
	"tester_id": TESTER,
	"demo_ver": false,
	"last_save_date": {},
	"is_ending": false,
	"chapter": 0,
	"play_time": 0,
	"game_clear_count": 0,
	"ticket_total": 0,
	"ticket_num": 0,
	"extra_cost": 0,
	"route_coin": 0,
	"buyed_route_coin": {},
	"ticket_shop_used": 0,
	"ability": {},
	"equipment": [],
	"npc_info": {},
	"butler_stack_exp": 0,
	"current_partner": Constants.NpcTypes.REINA,
	"read_event": [],
	"route_data": {},
	"current_route": [],
	"current_route_base": [],
	"kankan_destination": {},
	"destination_info": {},
	"route_hint": [],
	"box_map": [],
	"box_getted_stage": [],
	"omt_enabled": true,
}

## [KR] 현재 활성화된 세이브 슬롯의 데이터를 보관하는 딕셔너리.
## [br]게임 내 모든 시스템이 이 변수를 통해 진행 상태를 읽고 쓴다.
## [method new_game] 또는 [method load_save_file]로 초기화되며,
## [method game_save]로 파일에 기록된다.
## [EN] Dictionary holding the data of the currently active save slot.
## [br]All in-game systems read and write progress through this variable.
## Initialized by [method new_game] or [method load_save_file],
## and written to file by [method game_save].
var save_data: Dictionary = {}
var _block_auto_save: bool = false

#region META_SYSTEM
## [KR] 노드 초기화. 시그널을 연결하고, 윈도우를 화면 중앙에 배치한 뒤 새 게임을 시작한다.
## [EN] Node initialization. Connects signals, centers the window on screen, and starts a new game.
func _ready():
	# [KR] 시그널 연결
	# [EN] Connect signals
	GameEvents.ability_upgrade_added.connect(add_ability_upgrade)
	
	## [KR] 게임 시작 시 화면 가운데로 이동
	## [EN] Move to center of screen on game start
	set_window_center()
	
	# [KR] 세이브 파일을 불러옴 (슬롯 0) *테스트용*
	# [EN] Load save file (slot 0) *for testing*
	new_game()
	#load_save_file(save_slot)

## [KR] 게임 윈도우를 모니터 화면 중앙에 배치한다.
## [EN] Centers the game window on the monitor screen.
func set_window_center():
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var client_size = get_window().size
	var decoration_height = get_window().get_size_with_decorations().y - client_size.y
	var new_pos = screen_center - client_size / 2
	new_pos.y = max(new_pos.y, DisplayServer.screen_get_position().y + decoration_height)
	get_window().set_position(new_pos)

## [KR] 새 게임을 시작한다. [member save_data]를 [constant DEFAULT_SAVE_DATA] 복사본으로 초기화한다.
## [br][method ensure_default_fields]를 호출하여 누락 필드를 보정한다.
## [br]접근 키: [member save_data] 전체 (딥 카피로 초기화)
## [EN] Starts a new game. Initializes [member save_data] with a copy of [constant DEFAULT_SAVE_DATA].
## [br]Calls [method ensure_default_fields] to fill in missing fields.
## [br]Access key: entire [member save_data] (initialized via deep copy)
func new_game():
	print("new game")
	save_slot = -1
	save_data = DEFAULT_SAVE_DATA.duplicate(true)  # [KR] 기본 템플릿을 복사해서 초기화 / [EN] Copy default template to initialize
	#print(save_data)
	ensure_default_fields(save_data, DEFAULT_SAVE_DATA)

## [KR] 현재 세이브가 한 번도 저장된 적 없는 새 게임인지 확인한다.
## [br]접근 키: [code]last_save_date[/code] — 빈 딕셔너리이면 새 게임으로 판단.
## [EN] Checks if the current save is a new game that has never been saved.
## [br]Access key: [code]last_save_date[/code] — considered a new game if empty dictionary.
func is_new_game() -> bool:
	if save_data["last_save_date"] == {}:
		return true
	return false

## [KR] [param slot_num]번 슬롯의 세이브 파일을 로드하여 [member save_data]에 저장한다.
## [br]파일 경로: [code]user://game{slot_num}.save[/code]
## [br]파일이 없으면 로드하지 않고 반환한다. 로드 후 [method ensure_default_fields]로
## 누락 필드를 보정한다.
## [EN] Loads the save file from slot [param slot_num] and stores it in [member save_data].
## [br]File path: [code]user://game{slot_num}.save[/code]
## [br]Returns without loading if file doesn't exist. After loading, fills in
## missing fields with [method ensure_default_fields].
func load_save_file(slot_num: int):
	# [KR] 저장 경로 설정
	# [EN] Set save path
	var save_slot_path := SAVE_FILE_PATH + SAVE_FILE_NAME + str(slot_num) + SAVE_FILE_TYPE
	
	# [KR] 파일이 없으면 기본 데이터로 초기화
	# [EN] Initialize with default data if file doesn't exist
	if !FileAccess.file_exists(save_slot_path):
		print("No saved file exists.")
		#save_data = DEFAULT_SAVE_DATA.duplicate(true)  # 기본 템플릿을 복사해서 초기화
		return
	
	# [KR] 파일이 있으면 세이브 파일을 열어 데이터 로드
	# [EN] Open save file and load data if file exists
	var file = FileAccess.open(save_slot_path, FileAccess.READ)
	save_data = file.get_var()

	# [KR] 데모 버전에서 저장된 파일은 본편에서 로드하지 않음
	if save_data.get("demo_ver", false) == true:
		print("Demo save file cannot be used in the main game. (slot: %d)" % slot_num)
		save_data = {}
		return

	save_slot = slot_num
	_block_auto_save = true
	# [KR] 로드된 데이터에서 누락된 필드가 있으면 기본값으로 추가
	# [EN] Add default values for any missing fields in loaded data
	ensure_default_fields(save_data, DEFAULT_SAVE_DATA)
	# [KR] 로드된 세이브 기준으로 도전과제 조건 재판정 (소급 해금)
	AchievementManager.evaluate_all()

## [KR] [param target] 딕셔너리에 [param default] 템플릿 대비 누락된 키를 기본값으로 추가한다.
## [br]중첩 딕셔너리는 재귀적으로 처리한다. 업데이트로 새 세이브 키가 추가되었을 때
## 기존 세이브 파일의 하위 호환성을 보장하기 위한 설계이다.
## [EN] Adds missing keys to [param target] dictionary based on [param default] template with default values.
## [br]Nested dictionaries are processed recursively. Designed to ensure backward
## compatibility of existing save files when new save keys are added in updates.
func ensure_default_fields(target: Dictionary, default: Dictionary):
	for key in default.keys():
		# [KR] 필드가 없는 경우 기본값으로 초기화
		# [EN] Initialize with default value if field is missing
		if not target.has(key):
			if typeof(default[key]) in [TYPE_DICTIONARY, TYPE_ARRAY]:
				target[key] = default[key].duplicate(true)
			else:
				target[key] = default[key]
		# [KR] 중첩된 딕셔너리인 경우 재귀적으로 필드 확인
		# [EN] Recursively check fields for nested dictionaries
		elif typeof(target[key]) == TYPE_DICTIONARY and typeof(default[key]) == TYPE_DICTIONARY:
			ensure_default_fields(target[key], default[key])

## [KR] [param slot_num]번 슬롯에 게임을 저장한다.
## [br]저장 시점의 시스템 시각과 플레이 타임을 기록한 뒤 [method _save]를 호출한다.
## [br]접근 키: [code]last_save_date[/code], [code]play_time[/code], [code]chapter[/code],
## [code]ticket_total[/code], [code]ticket_num[/code], [code]ticket_shop_used[/code],
## [code]equipment[/code], [code]read_event[/code], [code]route_data[/code]
## [EN] Saves the game to slot [param slot_num].
## [br]Records system time and play time at the moment of saving, then calls [method _save].
## [br]Access keys: [code]last_save_date[/code], [code]play_time[/code], [code]chapter[/code],
## [code]ticket_total[/code], [code]ticket_num[/code], [code]ticket_shop_used[/code],
## [code]equipment[/code], [code]read_event[/code], [code]route_data[/code]
func game_save(slot_num: int):
	save_data["last_save_date"] = Time.get_datetime_dict_from_system()
	save_data["last_save_date"]["unix_time"] = Time.get_unix_time_from_system()
	add_play_time()
	_save(slot_num)
	print("=====================")
	print("🌟 Game save complete 🌟")
	if slot_num == Constants.AUTO_SAVE_INDEX:
		print("▶ Slot:", "Auto save")
	else:
		print("▶ Slot:", slot_num)
	print("▶ Save time:", save_data["last_save_date"])
	print("▶ Current chapter:", save_data["chapter"])
	print("▶ Play time(sec):", save_data["play_time"])
	print("▶ Total tickets:", save_data["ticket_total"])
	print("▶ Current ticket count:", save_data["ticket_num"])
	print("▶ Tickets used:", save_data["ticket_shop_used"])
	print("▶ Equipment count:", save_data["equipment"].size())
	print("▶ Read event count:", save_data["read_event"].size())
	print("▶ Route discovery count:", save_data["route_data"].size())
	print("=====================")

## [KR] 자동 저장을 실행한다. 가장 오래된 오토세이브 슬롯에 저장하고 알림을 표시한다.
## [EN] Executes auto-save. Saves to the oldest auto-save slot and displays a notification.
func auto_save():
	if _block_auto_save:
		_block_auto_save = false
		return
	game_save(_get_oldest_auto_save_slot())
	NotionEvent.notion("NOTI_AUTOSAVE_COMPLETE")

## [KR] 오토세이브 슬롯 중 가장 오래된(또는 비어있는) 슬롯 번호를 반환한다.
## [EN] Returns the oldest (or empty) slot number among the auto-save slots.
func _get_oldest_auto_save_slot() -> int:
	var oldest_slot := Constants.AUTO_SAVE_INDEX
	var oldest_time := INF
	for i in Constants.AUTO_SAVE_SLOT_COUNT:
		var slot_num = Constants.AUTO_SAVE_INDEX + i
		var data = get_slot_save_data(slot_num)
		if data == {}:
			return slot_num
		var t: float = data.get("last_save_date", {}).get("unix_time", 0.0)
		if t < oldest_time:
			oldest_time = t
			oldest_slot = slot_num
	return oldest_slot

## [KR] [param slot_num]번 슬롯에 [member save_data]를 파일로 기록하는 내부 함수.
## [br]파일 경로: [code]user://game{slot_num}.save[/code]
## [EN] Internal function that writes [member save_data] to file for slot [param slot_num].
## [br]File path: [code]user://game{slot_num}.save[/code]
func _save(slot_num: int):
	# [KR] 저장 경로 설정
	# [EN] Set save path
	var save_slot_path := SAVE_FILE_PATH + SAVE_FILE_NAME + str(slot_num) + SAVE_FILE_TYPE
	# [KR] 세이브 파일 열기 (쓰기 모드)
	# [EN] Open save file (write mode)
	var file = FileAccess.open(save_slot_path, FileAccess.WRITE)
	# [KR] 세이브 데이터 저장
	# [EN] Store save data
	file.store_var(save_data)

## [KR] [param slot_num]번 슬롯의 세이브 데이터를 파일에서 직접 읽어 반환한다.
## [br]현재 [member save_data]에 영향을 주지 않는다. 파일이 없으면 빈 딕셔너리를 반환한다.
## [br]회상방 해금 판정, 슬롯 목록 표시 등에 사용된다.
## [EN] Reads and returns save data from slot [param slot_num] directly from file.
## [br]Does not affect the current [member save_data]. Returns empty dictionary if file doesn't exist.
## [br]Used for recollection room unlock checks, slot list display, etc.
func get_slot_save_data(slot_num: int):
	var save_slot_path := SAVE_FILE_PATH + SAVE_FILE_NAME + str(slot_num) + SAVE_FILE_TYPE
	var save_info = {}
	if FileAccess.file_exists(save_slot_path):
		var file = FileAccess.open(save_slot_path, FileAccess.READ)
		save_info = file.get_var()
		# [KR] 데모 세이브 파일은 빈 딕셔너리로 반환
		if save_info.get("demo_ver", false) == true:
			return {}
	return save_info

## [KR] 전체 슬롯을 순회하여 세이브 데이터가 하나라도 존재하는지 확인한다.
## [br]수동 슬롯([constant SAVE_SLOT_MAX]개)뿐 아니라 오토세이브 슬롯
## ([constant Constants.AUTO_SAVE_INDEX]부터 [constant Constants.AUTO_SAVE_SLOT_COUNT]개)도 검사한다.
## [br]Why: 오토세이브만 있고 수동 저장이 없는 경우에도 타이틀에서 "이어하기" 버튼이
## 떠야 하므로, 오토세이브 슬롯을 빼면 로드가 불가능해진다.
## [EN] Iterates all slots to check if any save data exists.
## [br]Checks both manual slots and auto-save slots, used to determine whether
## to show the "Continue" button on the title screen.
func has_anyone_save_data()-> bool:
	for i in SAVE_SLOT_MAX:
		var data = get_slot_save_data(i)
		if data != null and data != {}:
			return true
	for i in Constants.AUTO_SAVE_SLOT_COUNT:
		var data = get_slot_save_data(Constants.AUTO_SAVE_INDEX + i)
		if data != null and data != {}:
			return true
	return false

## [KR] 에필로그 대화 종료 시 호출. 현재 세이브의 엔딩 클리어 플래그를 설정한다.
## [br]접근 키: [code]is_ending[/code] — [code]true[/code]로 설정.
## [br]이 플래그는 [method is_unlock_recollect]에서 회상방 해금 조건으로 사용된다.
## [EN] Called when epilogue dialogue ends. Sets the ending clear flag for the current save.
## [br]Access key: [code]is_ending[/code] — set to [code]true[/code].
## [br]This flag is used as an unlock condition for the recollection room in [method is_unlock_recollect].
func set_unlock_recollect():
	save_data["is_ending"] = true
	ending_reached.emit()

## [KR] 전체 슬롯을 순회하여 엔딩을 클리어한 세이브가 있는지 확인한다.
## [br]하나라도 [code]is_ending == true[/code]인 슬롯이 있으면 회상방을 해금한다.
## [br]전체 슬롯을 검사하는 이유: 플레이어가 어떤 슬롯에서든 엔딩을 봤으면 해금되어야 하므로.
## [EN] Iterates all slots to check if any save has cleared the ending.
## [br]Unlocks the recollection room if any slot has [code]is_ending == true[/code].
## [br]Reason for checking all slots: should be unlocked if the player saw the ending in any slot.
func is_unlock_recollect()-> bool:
	var current_ending:bool = false
	for i in SAVE_SLOT_MAX:
		var data = get_slot_save_data(i)
		if data.has("is_ending"):
			if data["is_ending"] == true:
				current_ending = true
				print("Ending data exists in save file #%d, recollection feature unlocked"%(i+1))
				break
	# [KR] 오토세이브 슬롯도 검사. 수동 저장 없이 오토세이브에만 엔딩 기록이 있는 경우 해금 누락 방지.
	if not current_ending:
		for i in Constants.AUTO_SAVE_SLOT_COUNT:
			var data = get_slot_save_data(Constants.AUTO_SAVE_INDEX + i)
			if data.has("is_ending") and data["is_ending"] == true:
				current_ending = true
				print("Ending data exists in auto-save slot #%d, recollection feature unlocked"%(Constants.AUTO_SAVE_INDEX + i))
				break
	return current_ending

## [KR] 회상방 진입 시 호출. 전체 세이브 슬롯을 순회하여 NPC별 해금된 이벤트 목록을 수집한다.
## [br]접근 키: [code]npc_info[/code] → [code]unlock_event[/code]
## [br]반환값: [code]{ npc_type: [event_id, ...] }[/code] 형태의 딕셔너리.
## [br]모든 슬롯을 순회하는 이유: 각 슬롯마다 해금된 이벤트가 다를 수 있으므로 합집합을 구한다.
## [EN] Called when entering the recollection room. Iterates all save slots to collect unlocked event lists per NPC.
## [br]Access key: [code]npc_info[/code] → [code]unlock_event[/code]
## [br]Return value: dictionary in the form [code]{ npc_type: [event_id, ...] }[/code].
## [br]Reason for iterating all slots: each slot may have different unlocked events, so a union is computed.
func get_all_recollection_events_grouped_by_npc() -> Dictionary:
	var grouped_events: Dictionary = {}

	for i in SAVE_SLOT_MAX:
		_collect_unlock_events(get_slot_save_data(i), grouped_events)
	# [KR] 오토세이브 슬롯도 합산. 오토세이브에만 해금분이 있는 경우 회상씬 누락 방지.
	for i in Constants.AUTO_SAVE_SLOT_COUNT:
		_collect_unlock_events(get_slot_save_data(Constants.AUTO_SAVE_INDEX + i), grouped_events)
	return grouped_events

## [KR] 단일 슬롯 데이터의 해금 이벤트를 [param grouped_events]에 NPC별로 합집합 누적한다.
func _collect_unlock_events(data, grouped_events: Dictionary) -> void:
	if not data.has("npc_info"):
		return
	for npc_type in data["npc_info"].keys():
		var npc_data = data["npc_info"][npc_type]
		if npc_data.has("unlock_event"):
			if not grouped_events.has(npc_type):
				grouped_events[npc_type] = []
			for event_id in npc_data["unlock_event"]:
				if not grouped_events[npc_type].has(event_id):
					grouped_events[npc_type].append(event_id)
#endregion

#region ABILITY
## [KR] 어빌리티 업그레이드 정보를 [member save_data]에 저장한다.
## [br]해당 업그레이드가 없으면 초기 구조를 생성한 뒤 수량을 갱신한다.
## [br]접근 키: [code]ability[/code] → [code]{upgrade_id: {quantity: int}}[/code]
## [EN] Saves ability upgrade info to [member save_data].
## [br]Creates initial structure if the upgrade doesn't exist, then updates the quantity.
## [br]Access key: [code]ability[/code] → [code]{upgrade_id: {quantity: int}}[/code]
func add_ability_upgrade(_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	# [KR] 해당 업그레이드가 없으면 초기화
	# [EN] Initialize if the upgrade doesn't exist
	if !save_data["ability"].has(_upgrade.id):
		save_data["ability"][_upgrade.id] = {
			"quantity": 0
		}
	# [KR] 업그레이드 수량 갱신
	# [EN] Update upgrade quantity
	save_data["ability"][_upgrade.id]["quantity"] = current_upgrades[_upgrade.id]["quantity"]

## [KR] 장비 아이템을 [member save_data]에 추가한다. 이미 존재하면 무시한다.
## [br]접근 키: [code]equipment[/code] (Array)
## [EN] Adds an equipment item to [member save_data]. Ignored if already exists.
## [br]Access key: [code]equipment[/code] (Array)
func add_equipment(item_id:String):
	if !save_data["equipment"].has(item_id):
		save_data["equipment"].append(item_id)
		
## [KR] 장비 아이템을 [member save_data]에서 제거한다.
## [br]접근 키: [code]equipment[/code] (Array)
## [EN] Removes an equipment item from [member save_data].
## [br]Access key: [code]equipment[/code] (Array)
func erase_equipment(item_id:String):
	if save_data["equipment"].has(item_id):
		save_data["equipment"].erase(item_id)

## [KR] 현재 장착 중인 장비 목록을 반환한다.
## [br]접근 키: [code]equipment[/code] (Array)
## [EN] Returns the list of currently equipped items.
## [br]Access key: [code]equipment[/code] (Array)
func get_equipment_array()->Array:
	return save_data["equipment"]

## [KR] 장착 중인 장비 목록에 [param item_id]가 존재하는지 확인한다.
## [br]접근 키: [code]equipment[/code] (Array)
## [EN] Checks if [param item_id] exists in the equipped items list.
## [br]Access key: [code]equipment[/code] (Array)
func has_equipment(item_id: String)-> bool:
	if save_data["equipment"].has(item_id):
		return true
	return false

## [KR] 추가 비용 값을 반환한다. 키가 없으면 [code]0[/code]으로 초기화한다.
## [br]접근 키: [code]extra_cost[/code]
## [EN] Returns the extra cost value. Initializes to [code]0[/code] if key doesn't exist.
## [br]Access key: [code]extra_cost[/code]
func get_extra_cost()-> int:
	init_save_data("extra_cost", 0)
	return save_data["extra_cost"]

## [KR] 추가 비용을 [param cost]만큼 누적한다.
## [br]접근 키: [code]extra_cost[/code]
## [EN] Accumulates extra cost by [param cost].
## [br]Access key: [code]extra_cost[/code]
func add_extra_cost(cost: int):
	init_save_data("extra_cost", 0)
	save_data["extra_cost"] += cost


#endregion

#region TICKET

## [KR] [param upgrade_id]에 해당하는 어빌리티 업그레이드의 보유 수량을 반환한다.
## [br]접근 키: [code]ability[/code] → [code]{upgrade_id: {quantity: int}}[/code]
## [EN] Returns the owned quantity of the ability upgrade for [param upgrade_id].
## [br]Access key: [code]ability[/code] → [code]{upgrade_id: {quantity: int}}[/code]
func get_upgrade_count(upgrade_id: String) -> int:
	if save_data["ability"].has(upgrade_id):
		return save_data["ability"][upgrade_id]["quantity"]
	return 0

## [KR] 현재 어빌리티 업그레이드 데이터의 복사본을 반환한다.
## [br]접근 키: [code]ability[/code] (딕셔너리를 duplicate하여 반환)
## [EN] Returns a copy of the current ability upgrade data.
## [br]Access key: [code]ability[/code] (returned by duplicating the dictionary)
func get_current_upgrade(_current_upgrade: Dictionary) -> Dictionary:
	return save_data["ability"].duplicate()

## [KR] 세이브 데이터의 어빌리티 딕셔너리를 직접 참조로 반환한다.
## [br]접근 키: [code]ability[/code]
## [EN] Returns the ability dictionary from save data as a direct reference.
## [br]Access key: [code]ability[/code]
func get_save_data_ability() -> Dictionary:
	return save_data["ability"]

## [KR] [param item_name]에 해당하는 어빌리티가 존재하는지 확인한다.
## [br]접근 키: [code]ability[/code]
## [EN] Checks if an ability for [param item_name] exists.
## [br]Access key: [code]ability[/code]
func has_ability(item_name: String)-> bool:
	if save_data["ability"].has(item_name):
		return true
	return false

## [KR] 누적 획득 티켓 총량을 반환한다.
## [br]접근 키: [code]ticket_total[/code]
## [EN] Returns the total accumulated tickets earned.
## [br]Access key: [code]ticket_total[/code]
func get_ticket_total()-> int:
	if not save_data.has("ticket_total"):
		save_data["ticket_total"] = 0
	return save_data["ticket_total"]

## [KR] 누적 획득 티켓에 [param add_ticket]만큼 더한다.
## [br]접근 키: [code]ticket_total[/code]
## [EN] Adds [param add_ticket] to the total accumulated tickets.
## [br]Access key: [code]ticket_total[/code]
func add_ticket_total(add_ticket: int):
	if not save_data.has("ticket_total"):
		save_data["ticket_total"] = 0
	save_data["ticket_total"] += add_ticket

## [KR] 상점에서 사용한 티켓 수를 반환한다.
## [br]접근 키: [code]ticket_shop_used[/code]
## [EN] Returns the number of tickets used in the shop.
## [br]Access key: [code]ticket_shop_used[/code]
func get_ticket_shop_used()-> int:
	if not save_data.has("ticket_shop_used"):
		save_data["ticket_shop_used"] = 0
	return save_data["ticket_shop_used"]

## [KR] 상점 사용 티켓 수에 [param add_ticket]만큼 누적한다.
## [br]접근 키: [code]ticket_shop_used[/code]
## [EN] Accumulates [param add_ticket] to the shop-used ticket count.
## [br]Access key: [code]ticket_shop_used[/code]
func add_ticket_shop_used(add_ticket: int):
	if not save_data.has("ticket_shop_used"):
		save_data["ticket_shop_used"] = 0
	save_data["ticket_shop_used"] += add_ticket

## [KR] 현재 보유 중인 티켓 수를 반환한다.
## [br]접근 키: [code]ticket_num[/code]
## [EN] Returns the number of currently held tickets.
## [br]Access key: [code]ticket_num[/code]
func get_ticket_num() -> int:
	return save_data["ticket_num"]

## [KR] 현재 티켓 보유량을 [param current_ticket] 값으로 갱신한다.
## [br]접근 키: [code]ticket_num[/code]
## [EN] Updates the current ticket count to the [param current_ticket] value.
## [br]Access key: [code]ticket_num[/code]
func ticket_count_update(current_ticket: int):
	save_data["ticket_num"] = current_ticket

#endregion

#region NPC
## [KR] [param npc]의 세이브 정보를 반환한다. 등록되지 않은 NPC면 빈 딕셔너리를 반환한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_name: {level, exp, stack_ticket, ...}}[/code]
## [EN] Returns the save info for [param npc]. Returns empty dictionary if NPC is unregistered.
## [br]Access key: [code]npc_info[/code] → [code]{npc_name: {level, exp, stack_ticket, ...}}[/code]
func get_npc_info(npc: Npc) -> Dictionary:
	if save_data["npc_info"].has(npc.npc_name):
		return save_data["npc_info"][npc.npc_name]
	return {}

## [KR] [param npc_type]에 해당하는 NPC의 호감도 레벨을 반환한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {level: int}}[/code]
## [EN] Returns the affection level of the NPC for [param npc_type].
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {level: int}}[/code]
func get_npc_love_level(npc_type: int)-> int:
	if not save_data["npc_info"].has(npc_type):
		return 0
	if not save_data["npc_info"][npc_type].has("level"):
		return 0
	return save_data["npc_info"][npc_type].level

## [KR] 모든 주요 NPC의 호감도 레벨 합산값을 반환한다.
## [br]접근 키: [code]npc_info[/code] (레이나, 마이의 [code]level[/code])
## [EN] Returns the sum of affection levels for all main NPCs.
## [br]Access key: [code]npc_info[/code] (Reina and Mai's [code]level[/code])
func get_npc_total_love_level()-> int:
	var reina_love:int = get_npc_love_level(Constants.NPC_OL)
	var mai_love:int = get_npc_love_level(Constants.NPC_GYARU)
	return reina_love + mai_love

## [KR] 현재 파트너 NPC를 [param partner_type]으로 설정한다.
## [br]접근 키: [code]current_partner[/code]
## [EN] Sets the current partner NPC to [param partner_type].
## [br]Access key: [code]current_partner[/code]
func set_current_partner(partner_type: int):
	save_data["current_partner"] = partner_type

## [KR] 현재 파트너 NPC 타입을 반환한다.
## [br]접근 키: [code]current_partner[/code]
## [EN] Returns the current partner NPC type.
## [br]Access key: [code]current_partner[/code]
func get_current_partner() -> int:
	return save_data["current_partner"]
## [KR] [param npc]의 호감도 정보를 [member save_data]에 갱신한다.
## [br]해당 NPC가 미등록 상태면 초기 구조([code]level[/code], [code]exp[/code], [code]stack_ticket[/code])를 생성한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_name: {level, exp, stack_ticket}}[/code]
## [EN] Updates the affection info for [param npc] in [member save_data].
## [br]Creates initial structure ([code]level[/code], [code]exp[/code], [code]stack_ticket[/code]) if NPC is unregistered.
## [br]Access key: [code]npc_info[/code] → [code]{npc_name: {level, exp, stack_ticket}}[/code]
func npc_info_update(npc: Npc):
	# [KR] 해당 NPC가 없으면 초기화
	# [EN] Initialize if the NPC doesn't exist
	if !save_data["npc_info"].has(npc.npc_name):
		save_data["npc_info"][npc.npc_name] = {
			"level": 0,
			"exp": 0,
			"stack_ticket": 0
		}
	# [KR] NPC의 호감도와 경험치 정보 갱신
	# [EN] Update the NPC's affection and experience info
	save_data["npc_info"][npc.npc_name]["level"] = npc.love_level
	save_data["npc_info"][npc.npc_name]["exp"] = npc.love_exp
	save_data["npc_info"][npc.npc_name]["stack_ticket"] = npc.stack_ticket

## [KR] [param npc_type] NPC에 [param event_name] 이벤트를 해금 목록에 추가한다.
## [br]이미 해금된 이벤트면 무시한다. 회상방 시스템에서 참조된다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {unlock_event: []}}[/code]
## [EN] Adds [param event_name] event to the unlock list for [param npc_type] NPC.
## [br]Ignores if the event is already unlocked. Referenced by the recollection room system.
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {unlock_event: []}}[/code]
func add_npc_unlock_event(npc_type: int, event_name: String):
	if not save_data["npc_info"].has(npc_type):
		save_data["npc_info"][npc_type] = {
			"unlock_event" : []
		}
	if not save_data["npc_info"][npc_type].has("unlock_event"):
		save_data["npc_info"][npc_type]["unlock_event"] = []
	if save_data["npc_info"][npc_type]["unlock_event"].has(event_name):
		return
	save_data["npc_info"][npc_type]["unlock_event"].append(event_name)
	event_unlocked.emit(npc_type, event_name)

## [KR] [param npc_type] NPC의 [param event_name] 이벤트가 해금되었는지 확인한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {unlock_event: []}}[/code]
## [EN] Checks if [param event_name] event is unlocked for [param npc_type] NPC.
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {unlock_event: []}}[/code]
func get_npc_unlock_event(npc_type: int, event_name: String)-> bool:
	if not save_data["npc_info"].has(npc_type):
		return false
	if not save_data["npc_info"][npc_type].has("unlock_event"):
		push_warning("unlock_event 항목이 없습니다")
		return false
	if save_data["npc_info"][npc_type]["unlock_event"].has(event_name):
		return true
	else:
		return false

## [KR] [param npc_type] NPC의 해금된 이벤트 목록을 배열로 반환한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {unlock_event: []}}[/code]
## [EN] Returns the unlocked event list for [param npc_type] NPC as an array.
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {unlock_event: []}}[/code]
func get_npc_unlock_event_list(npc_type: int)-> Array:
	if not save_data["npc_info"].has(npc_type):
		return []
	if not save_data["npc_info"][npc_type].has("unlock_event"):
		push_warning("unlock_event 항목이 없습니다")
		return []
	return save_data["npc_info"][npc_type]["unlock_event"]

## [KR] [param npc_type] NPC의 누적 티켓 수를 [param stack_ticket]으로 설정한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {stack_ticket: int}}[/code]
## [EN] Sets the accumulated ticket count for [param npc_type] NPC to [param stack_ticket].
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {stack_ticket: int}}[/code]
func set_npc_stack_ticket(npc_type: int, stack_ticket: int):
	if not save_data["npc_info"][npc_type].has("stack_ticket"):
		save_data["npc_info"][npc_type]["stack_ticket"] = []
	save_data["npc_info"][npc_type]["stack_ticket"] = stack_ticket

## [KR] 집사(Butler)의 잔여 경험치를 [param stack_exp]만큼 누적 저장한다.
## [br]레벨업 후 남은 초과 경험치를 보존하기 위한 설계이다.
## [br]접근 키: [code]butler_stack_exp[/code]
## [EN] Accumulates and saves the butler's remaining experience by [param stack_exp].
## [br]Designed to preserve overflow experience after leveling up.
## [br]Access key: [code]butler_stack_exp[/code]
func set_butler_stack_exp(stack_exp: int):
	if not save_data.has("butler_stack_exp"):
		save_data["butler_stack_exp"] = 0
	save_data["butler_stack_exp"] += stack_exp

## [KR] 집사의 누적 잔여 경험치를 반환하고 [code]0[/code]으로 초기화한다.
## [br]팝 방식으로 동작하여, 한 번 꺼내면 소진된다.
## [br]접근 키: [code]butler_stack_exp[/code]
## [EN] Returns the butler's accumulated remaining experience and resets it to [code]0[/code].
## [br]Operates in a pop fashion — once retrieved, it is consumed.
## [br]Access key: [code]butler_stack_exp[/code]
func popout_butler_stack_exp()-> int:
	if not save_data.has("butler_stack_exp"):
		save_data["butler_stack_exp"] = 0
	
	var stack_exp: int = save_data["butler_stack_exp"]
	save_data["butler_stack_exp"] = 0
	return stack_exp

## [KR] [param npc_type] NPC의 누적 티켓 수를 반환한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {stack_ticket: int}}[/code]
## [EN] Returns the accumulated ticket count for [param npc_type] NPC.
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {stack_ticket: int}}[/code]
func get_npc_stack_ticket(npc_type: int)-> int:
	if not save_data["npc_info"].has(npc_type):
		return 0
	if not save_data["npc_info"][npc_type].has("stack_ticket"):
		#print("stack_ticket 항목이 없습니다")
		return 0
	return save_data["npc_info"][npc_type]["stack_ticket"]
	
## [KR] [param npc_type] NPC의 에로 게이지를 [param ero_gage] 값으로 설정한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {ero_gage: int}}[/code]
## [EN] Sets the ero gauge for [param npc_type] NPC to [param ero_gage].
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {ero_gage: int}}[/code]
func set_npc_ero_gage(npc_type: int, ero_gage: int):
	if not save_data["npc_info"].has(npc_type):
		save_data["npc_info"][npc_type] = {}
	if not save_data["npc_info"][npc_type].has("ero_gage"):
		save_data["npc_info"][npc_type]["ero_gage"] = []
	save_data["npc_info"][npc_type]["ero_gage"] = ero_gage

## [KR] [param npc_type] NPC의 에로 게이지 값을 반환한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {ero_gage: int}}[/code]
## [EN] Returns the ero gauge value for [param npc_type] NPC.
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {ero_gage: int}}[/code]
func get_npc_ero_gage(npc_type: int)-> int:
	if not save_data["npc_info"].has(npc_type):
		return 0
	if not save_data["npc_info"][npc_type].has("ero_gage"):
		#print("ero_gage 항목이 없습니다")
		return 0
	return save_data["npc_info"][npc_type]["ero_gage"]

## [KR] [param npc_type] NPC의 현재 경험치를 반환한다.
## [br]접근 키: [code]npc_info[/code] → [code]{npc_type: {exp: int}}[/code]
## [EN] Returns the current experience of [param npc_type] NPC.
## [br]Access key: [code]npc_info[/code] → [code]{npc_type: {exp: int}}[/code]
func get_npc_current_exp(npc_type: int)-> int:
	if not save_data["npc_info"].has(npc_type):
		return 0
	if not save_data["npc_info"][npc_type].has("exp"):
		return 0
	return save_data["npc_info"][npc_type]["exp"]

#endregion

#region READ_EVENT
## [KR] 읽은 이벤트 목록을 반환한다. 데이터가 없으면 빈 배열을 반환한다.
## [br]접근 키: [code]read_event[/code] (Array)
## [EN] Returns the read event list. Returns an empty array if no data exists.
## [br]Access key: [code]read_event[/code] (Array)
func get_read_event():
	if save_data["read_event"]:
		return save_data["read_event"]
	return []

## [KR] [param event_name] 이벤트를 이미 읽었는지 확인한다.
## [br]접근 키: [code]read_event[/code] (Array)
## [EN] Checks if [param event_name] event has already been read.
## [br]Access key: [code]read_event[/code] (Array)
func has_read_event(event_name: String) -> bool:
	if save_data["read_event"].has(event_name):
		return true
	return false

## [KR] [param event_name] 이벤트를 읽음 처리한다. 이미 읽은 이벤트면 무시한다.
## [br]접근 키: [code]read_event[/code] (Array)
## [EN] Marks [param event_name] event as read. Ignores if already read.
## [br]Access key: [code]read_event[/code] (Array)
func read_event_update(event_name: String):
	if !save_data.has("read_event"):
		save_data["read_event"] = []
	if save_data["read_event"].has(event_name):
		return
	save_data["read_event"].append(event_name)
#endregion

#region GAME_STATE
## [KR] 게임 클리어 횟수를 반환한다.
## [br]접근 키: [code]game_clear_count[/code]
## [EN] Returns the game clear count.
## [br]Access key: [code]game_clear_count[/code]
func get_game_clear_count()->int:
	#print("clear count = %d" %save_data["game_clear_count"])
	return save_data["game_clear_count"]

## [KR] 게임 클리어 시 호출. 클리어 횟수를 1 증가시킨다.
## [br]접근 키: [code]game_clear_count[/code]
## [EN] Called on game clear. Increments the clear count by 1.
## [br]Access key: [code]game_clear_count[/code]
func set_game_complete_count_up():
	save_data["game_clear_count"] += 1

## [KR] 게임 클리어 횟수를 [param count] 값으로 직접 설정한다.
## [br]접근 키: [code]game_clear_count[/code]
## [EN] Directly sets the game clear count to [param count].
## [br]Access key: [code]game_clear_count[/code]
func set_game_complete_count(count: int):
	save_data["game_clear_count"] = count

## [KR] 현재 챕터를 [param chapter] 값으로 설정한다.
## [br]접근 키: [code]chapter[/code]
## [EN] Sets the current chapter to [param chapter].
## [br]Access key: [code]chapter[/code]
func set_current_chapter(chapter : int):
	save_data["chapter"] = chapter

## [KR] 현재 챕터 번호를 반환한다.
## [br]접근 키: [code]chapter[/code]
## [EN] Returns the current chapter number.
## [br]Access key: [code]chapter[/code]
func get_current_chapter() -> int:
	return save_data["chapter"]
	
## [KR] 현재 세션의 플레이 타임을 [member save_data]에 누적한다.
## [br][code]GlobalGameManager[/code]에서 경과 시간을 가져와 합산한다.
## [br]접근 키: [code]play_time[/code]
## [EN] Accumulates the current session's play time into [member save_data].
## [br]Retrieves elapsed time from [code]GlobalGameManager[/code] and adds it.
## [br]Access key: [code]play_time[/code]
func add_play_time():
	var global_game_manager = get_tree().get_first_node_in_group("globalgamemanager") as GlobalGameManager
	if global_game_manager:
		var play_time_added = global_game_manager.get_play_time()
		save_data["play_time"] += play_time_added

## [KR] 총 플레이 타임(초)을 반환한다.
## [br]접근 키: [code]play_time[/code]
## [EN] Returns the total play time in seconds.
## [br]Access key: [code]play_time[/code]
func get_play_time()-> float:
	return save_data["play_time"]
#endregion

#region ROUTE
## [KR] 발견한 루트 정보 딕셔너리를 반환한다.
## [br]접근 키: [code]route_data[/code] (Dictionary)
## [EN] Returns the discovered route info dictionary.
## [br]Access key: [code]route_data[/code] (Dictionary)
func get_routes_dict() -> Dictionary:
	if !save_data.has("route_data"):
		save_data["route_data"] = {}
	return save_data["route_data"]

## [KR] [param stage_path] 스테이지의 루트 정보를 최초 발견 시에만 저장한다.
## [br]이미 발견된 루트는 무시한다. 최초 발견 시 [signal stage_first_clear]를 발신하고
## 알림을 표시한다.
## [br]접근 키: [code]route_data[/code] → [code]{stage_path: route_dict}[/code]
## [EN] Saves route info for [param stage_path] stage only on first discovery.
## [br]Ignores already discovered routes. On first discovery, emits [signal stage_first_clear]
## and displays a notification.
## [br]Access key: [code]route_data[/code] → [code]{stage_path: route_dict}[/code]
func set_route_data(stage_path: String, route: Dictionary):
	if !save_data.has("route_data"):
		save_data["route_data"] = {}
		
	if save_data["route_data"].has(stage_path):
		return
	# [KR] 최초 감지시에만 실행
	# [EN] Only executed on first detection
	stage_first_clear.emit()
	save_data["route_data"][stage_path] = route
	NotionEvent.notion("NOTI_FIRST_FIND_ROUTE")
	var message = tr("NOTI_FIND_ROUTE_VALUE")%(MetaProgression.get_routes_dict()as Dictionary).size()
	NotionEvent.notion(message)

## [KR] [param stage_path] 루트를 이미 발견(탐색 완료)했는지 확인한다.
## [br]접근 키: [code]route_data[/code]
## [EN] Checks if the route for [param stage_path] has already been discovered (exploration complete).
## [br]Access key: [code]route_data[/code]
func has_route_data(stage_path: String) -> bool:
	if !save_data.has("route_data"):
		save_data["route_data"] = {}
		
	if save_data["route_data"].has(stage_path):
		return true
	return false

#region KanKanNavi
## [KR] 칸칸네비의 기본 루트와 루트 목록을 설정한다.
## [br]기존 데이터를 초기화한 뒤 새로운 루트 정보로 교체한다.
## [br]접근 키: [code]current_route[/code], [code]current_route_base[/code] (Array)
## [EN] Sets KanKanNavi's base route and route list.
## [br]Clears existing data and replaces it with new route info.
## [br]Access key: [code]current_route[/code], [code]current_route_base[/code] (Array)
func set_base_route(base_route: Array, routes: Array):
	(save_data["current_route"] as Array).clear()
	(save_data["current_route"] as Array).append_array(base_route)
	(save_data["current_route_base"] as Array).clear()
	(save_data["current_route_base"] as Array).append_array(routes)

## [KR] 칸칸네비의 설정된 루트 정보를 모두 초기화한다.
## [br]접근 키: [code]current_route[/code], [code]current_route_base[/code] (Array)
## [EN] Clears all configured route info for KanKanNavi.
## [br]Access key: [code]current_route[/code], [code]current_route_base[/code] (Array)
func clear_setting_routes():
	(save_data["current_route"] as Array).clear()
	(save_data["current_route_base"] as Array).clear()

## [KR] 칸칸네비의 종착점을 [param destination]으로 설정한다.
## [br]접근 키: [code]kankan_destination[/code] (Dictionary)
## [EN] Sets KanKanNavi's destination to [param destination].
## [br]Access key: [code]kankan_destination[/code] (Dictionary)
func set_kankan_destination(destination: Dictionary):
	if !save_data.has("kankan_destination"):
		save_data["kankan_destination"] = {}
	save_data["kankan_destination"] = destination

## [KR] 칸칸네비의 종착점 정보를 초기화한다.
## [br]접근 키: [code]kankan_destination[/code]
## [EN] Clears KanKanNavi's destination info.
## [br]Access key: [code]kankan_destination[/code]
func clear_kankan_destination():
	save_data["kankan_destination"] = {}
		

## [KR] 칸칸네비에 설정된 종착점 정보를 반환한다. 미설정 시 빈 딕셔너리를 반환한다.
## [br]접근 키: [code]kankan_destination[/code] (Dictionary)
## [EN] Returns the configured destination info for KanKanNavi. Returns empty dictionary if unset.
## [br]Access key: [code]kankan_destination[/code] (Dictionary)
func get_kankan_destination()-> Dictionary:
	if !save_data.has("kankan_destination"):
		save_data["kankan_destination"] = {}
	return save_data["kankan_destination"]

## [KR] 칸칸네비의 기본 루트 배열을 반환한다.
## [br]접근 키: [code]current_route[/code] (Array)
## [EN] Returns KanKanNavi's base route array.
## [br]Access key: [code]current_route[/code] (Array)
func get_base_route()-> Array:
	if !save_data.has("current_route"):
		return []
	return save_data["current_route"]
#endregion

## [KR] 종착점 스테이지 클리어 시 방문 정보를 저장한다.
## [br]접근 키: [code]destination_info[/code] → [code]{stage_path: info_dict}[/code]
## [EN] Saves visit info when a destination stage is cleared.
## [br]Access key: [code]destination_info[/code] → [code]{stage_path: info_dict}[/code]
func set_current_destination_info(stage_path: String,  info:Dictionary):
	if !save_data.has("destination_info"):
		save_data["destination_info"] = {}
	save_data["destination_info"][stage_path] = info
	destination_cleared.emit()

## [KR] 방문한 종착점 정보 딕셔너리를 반환한다.
## [br]접근 키: [code]destination_info[/code] (Dictionary)
## [EN] Returns the visited destination info dictionary.
## [br]Access key: [code]destination_info[/code] (Dictionary)
func get_current_destination_info()->Dictionary:
	if !save_data.has("destination_info"):
		return {}
	return save_data["destination_info"]

## [KR] [param dest_path] 종착점을 이미 방문했는지 확인한다.
## [br]접근 키: [code]destination_info[/code]
## [EN] Checks if [param dest_path] destination has already been visited.
## [br]Access key: [code]destination_info[/code]
func has_visited_destination_route(dest_path: String)-> bool:
	if save_data["destination_info"].has(dest_path):
		return true
	return false

## [KR] 칸칸네비의 전체 루트 목록을 반환한다.
## [br]접근 키: [code]current_route_base[/code] (Array)
## [EN] Returns KanKanNavi's full route list.
## [br]Access key: [code]current_route_base[/code] (Array)
func get_routes()-> Array:
	if !save_data.has("current_route_base"):
		return []
	return save_data["current_route_base"]
#endregion

#region ROUTE_HINT
## [KR] 루트 힌트 목록을 반환한다. 데이터가 없으면 빈 배열을 반환한다.
## [br]접근 키: [code]route_hint[/code] (Array)
## [EN] Returns the route hint list. Returns an empty array if no data exists.
## [br]Access key: [code]route_hint[/code] (Array)
func get_route_hint_array()-> Array:
	create_save_data_array("route_hint")
	
	if save_data["route_hint"]:
		return save_data["route_hint"]
	return []

## [KR] 루트 힌트를 추가한다. 이미 존재하는 힌트면 무시한다.
## [br]주의: 직접 호출 시 알림 메시지가 출력되지 않는다.
## [code]GameEvents.emit_add_route_hint[/code]를 통해 호출해야 UI 알림이 표시된다.
## [br]접근 키: [code]route_hint[/code] (Array)
## [EN] Adds a route hint. Ignores if the hint already exists.
## [br]Note: No notification message is displayed when called directly.
## Must be called via [code]GameEvents.emit_add_route_hint[/code] for UI notification.
## [br]Access key: [code]route_hint[/code] (Array)
func add_route_hint(route_hint_id: String):
	create_save_data_array("route_hint")
		
	if save_data["route_hint"].has(route_hint_id):
		return
	save_data["route_hint"].append(route_hint_id)
	
	get_route_hint.emit()

## [KR] [param route_hint_id] 루트 힌트가 이미 추가되어 있는지 확인한다.
## [br]접근 키: [code]route_hint[/code] (Array)
## [EN] Checks if [param route_hint_id] route hint has already been added.
## [br]Access key: [code]route_hint[/code] (Array)
func has_route_hint(route_hint_id: String) -> bool:
	create_save_data_array("route_hint")
	
	if save_data["route_hint"].has(route_hint_id):
		return true
	return false

## [KR] [member save_data]에 [param array_name] 키가 없으면 빈 배열로 초기화한다.
## [br]배열형 세이브 데이터의 안전한 접근을 보장하는 유틸리티 함수.
## [EN] Initializes [param array_name] key in [member save_data] as an empty array if it doesn't exist.
## [br]Utility function that ensures safe access to array-type save data.
func create_save_data_array(array_name: String):
	if !save_data.has(array_name):
		save_data[array_name] = []

#endregion

#region CURRENCY_ITEM
## [KR] 루트 코인을 [param coin_num]만큼 증감한다. 음수를 전달하면 차감된다.
## [br]접근 키: [code]route_coin[/code]
## [EN] Increases or decreases route coins by [param coin_num]. Passing a negative value deducts.
## [br]Access key: [code]route_coin[/code]
func add_or_minus_route_coin(coin_num: int):
	init_save_data("route_coin", 0)
	save_data["route_coin"] += coin_num

## [KR] 현재 보유 중인 루트 코인 수를 반환한다.
## [br]접근 키: [code]route_coin[/code]
## [EN] Returns the number of currently held route coins.
## [br]Access key: [code]route_coin[/code]
func get_route_coin()-> int:
	init_save_data("route_coin", 0)
	return save_data["route_coin"]

## [KR] [param item_id] 재화 아이템의 구매 수량에 [param coin_num]만큼 누적한다.
## [br]접근 키: [code]buyed_route_coin[/code] → [code]{item_id: int}[/code]
## [EN] Accumulates [param coin_num] to the purchased quantity of [param item_id] currency item.
## [br]Access key: [code]buyed_route_coin[/code] → [code]{item_id: int}[/code]
func add_buyed_currency_item(item_id: String, coin_num: int):
	init_save_data("buyed_route_coin", {})
	save_data["buyed_route_coin"][item_id] += coin_num

## [KR] [param item_id] 재화 아이템의 누적 구매 수량을 반환한다.
## [br]접근 키: [code]buyed_route_coin[/code] → [code]{item_id: int}[/code]
## [EN] Returns the accumulated purchased quantity of [param item_id] currency item.
## [br]Access key: [code]buyed_route_coin[/code] → [code]{item_id: int}[/code]
func get_buyed_currency_item(item_id: String)-> int:
	init_save_data("buyed_route_coin", {})
	if not save_data["buyed_route_coin"].has(item_id):
		save_data["buyed_route_coin"][item_id] = 0
	return save_data["buyed_route_coin"][item_id]

#endregion

#region ITEM_BOX

## [KR] [param item_name] 아이템 박스의 맵 정보를 추가한다.
## [br]접근 키: [code]box_map[/code] (Array)
## [EN] Adds map info for [param item_name] item box.
## [br]Access key: [code]box_map[/code] (Array)
func add_box_map(item_name: String):
	init_save_data("box_map", [])
	save_data["box_map"].append(item_name)

## [KR] [param item_name] 아이템 박스 맵이 이미 등록되어 있는지 확인한다.
## [br]접근 키: [code]box_map[/code] (Array)
## [EN] Checks if [param item_name] item box map is already registered.
## [br]Access key: [code]box_map[/code] (Array)
func has_box_map(item_name: String)-> bool:
	init_save_data("box_map", [])
	if save_data["box_map"].has(item_name):
		return true
	return false

## [KR] [param stage_name] 스테이지에서 아이템 박스를 획득했음을 기록한다.
## [br]접근 키: [code]box_getted_stage[/code] (Array)
## [EN] Records that an item box was obtained in [param stage_name] stage.
## [br]Access key: [code]box_getted_stage[/code] (Array)
func add_box_getted_stage(stage_name: String):
	init_save_data("box_getted_stage", [])
	save_data["box_getted_stage"].append(stage_name)

## [KR] [param stage_name] 스테이지에서 아이템 박스를 이미 획득했는지 확인한다.
## [br]접근 키: [code]box_getted_stage[/code] (Array)
## [EN] Checks if an item box has already been obtained in [param stage_name] stage.
## [br]Access key: [code]box_getted_stage[/code] (Array)
func has_box_getted_stage(stage_name: String)-> bool:
	init_save_data("box_getted_stage", [])
	if save_data["box_getted_stage"].has(stage_name):
		return true
	return false

#endregion

## [KR] [member save_data]에 [param list_name] 키가 없으면 [param type] 기본값으로 초기화한다.
## [br]모든 세이브 데이터 접근 전 안전성을 보장하는 범용 유틸리티 함수.
## [br][method create_save_data_array]와 달리 모든 타입을 지원한다.
## [EN] Initializes [param list_name] key in [member save_data] with [param type] default value if it doesn't exist.
## [br]General-purpose utility function that ensures safety before all save data access.
## [br]Unlike [method create_save_data_array], supports all types.
func init_save_data(list_name: String, type: Variant):
	if not save_data.has(list_name):
		save_data[list_name] = type
