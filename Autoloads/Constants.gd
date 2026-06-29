## [KR] 게임 전체에서 사용되는 상수, 열거형, 리소스 프리로드를 관리하는 오토로드 싱글톤.
## [br]디버그 플래그, NPC 식별자, 스테이지 타입, 보상 수치, UI 리소스 경로 등
## 게임의 핵심 설정값을 중앙에서 정의한다.
## [EN] Autoload singleton that manages constants, enums, and resource preloads used throughout the game.
## [br]Defines core game settings centrally: debug flags, NPC identifiers, stage types, reward values, UI resource paths, etc.
extends Node

## [KR] 현재 빌드가 디버그 모드인지 여부. [method OS.is_debug_build]로 판별한다.
## [EN] Whether the current build is in debug mode. Determined by [method OS.is_debug_build].
var IS_DEBUG  := OS.is_debug_build()

## [KR] ──── 디버그 테스트 설정 ────
## 개발 및 테스트 시 특정 기능을 강제로 활성화/비활성화하는 플래그 모음.
## [b]릴리스 빌드 전에 모두 [code]false[/code]로 되돌려야 한다.[/b]
## [EN] ──── Debug test settings ────
## Collection of flags to force enable/disable specific features during development and testing.
## [b]All must be reverted to [code]false[/code] before release build.[/b]

## [KR] 디버그 빌드에선 인트로 자동 스킵, 릴리스 빌드에선 정상 재생. / [EN] Auto-skip intro in debug builds, play normally in release.
var INTRO_SKIP := IS_DEBUG
const SCENE_DEBUG:= false # [KR] gameplay scene에서 테스트할때 true로 변경 / [EN] Set to true when testing in gameplay scene
const FLOOR_MANAGER_ROUTE_DEBUG:= false
const PLAYER_DEBUG_MOD:= false
const RECOLLECTION_ALL_UNLOCK:= false
const ROUTE_ALL_UNLOCK:= false # [KR] 칸칸네비 테스트 / [EN] Kankan navi test
const KANKAN_TUTORIAL_SKIP:= false
const KANKAN_TUTORIAL_FORCE:= false # [KR] true 시 read_event 무시하고 튜토리얼 강제 실행 / [EN] Force tutorial regardless of read_event
const KANKAN_ROUTE_BUY_MODE_UNLOCK:= false
const ITEM_BOX_DEBUG:= false # [KR] 아이템 박스 챕터에 관계없이 등장 여부 / [EN] Whether item box appears regardless of chapter
const FREE_ACTION_TEST:= false # [KR] free_action_component만 독립적으로 테스트하고 싶을 때 true / [EN] Set to true when testing free_action_component independently
const TUTORIAL_PAGE_DEBUG:= false
const CHAPTER_SCREEN_DEBUG:= false
# [KR] true면 챕터 화면에서 루트 데이터와 무관하게 FIND·UNFIND·NEW 이변 아이콘을 각각 고정 개수만큼 띄워 효과음을 확인한다.
const CHAPTER_SCREEN_ANOMALY_SFX_DEBUG:= false
# [KR] 위 디버그가 켜졌을 때 각 상태별로 생성할 아이콘 개수.
const CHAPTER_SCREEN_ANOMALY_SFX_DEBUG_COUNT:= 5
const TUTORIAL_BOOK_TEST:= false
## [KR] true면 릴리스 빌드에서도 F1 개발자 치트 패널을 사용할 수 있다. (디버그 빌드는 항상 사용 가능)
## [KR] 출시 빌드에서는 false 유지 — 치트패널 차단.
const CHEAT_IN_RELEASE:= false

## [KR] 고스트 스테이지 아이템 디버그 시 건너뛰기 여부.
## [EN] Whether to skip during ghost stage item debug.
const ITEM_DEBUG_GHOST_SKIP:= false

## [KR] ──── NPC 정의 ────
## [EN] ──── NPC definitions ────

## [KR] NPC 캐릭터를 식별하는 열거형.
## [code]NONE[/code]은 미지정 상태([code]-1[/code])를 나타낸다.
## [EN] Enum for identifying NPC characters.
## [code]NONE[/code] represents unspecified state ([code]-1[/code]).
enum NpcTypes {NONE = -1, REINA, MAI, KONIAL, PAZUZU, BUTLER}

## [KR] ──── 스테이지 타입 ────
## 맵 노드의 종류를 구분하는 상수. 플로어 매니저에서 스테이지 분기에 사용된다.
## [EN] ──── Stage types ────
## Constants that distinguish map node types. Used for stage branching in floor manager.
const TYPE_BASE = 0
const TYPE_STAGE = 1
const TYPE_EVENT = 2
const TYPE_SAFE = 3
const TYPE_COMPLETE = 4

## [KR] ──── NPC / 플레이어 인덱스 ────
## 캐릭터 식별에 사용되는 정수 인덱스. [member PC_PLAYER]는 플레이어 전용 값이다.
## [EN] ──── NPC / Player indices ────
## Integer indices used for character identification. [member PC_PLAYER] is player-only value.
const PC_PLAYER = -1
const NPC_OL = 0
const NPC_GYARU = 1
const NPC_KONIAL = 2
const NPC_PAZUZU = 3
const NPC_BUTLER = 4

## [KR] ──── 파트너 레벨 및 정념 게이지 ────
## 파트너 NPC의 최대 레벨, 정념 게이지 한도, 챕터별 레벨 상한을 정의한다.
## [EN] ──── Partner level and passion gauge ────
## Defines partner NPC max level, passion gauge limit, and per-chapter level caps.

## [KR] 파트너 NPC가 도달할 수 있는 최대 레벨.
## [EN] Maximum level a partner NPC can reach.
const PARTNER_MAX_LEVEL := 8
## [KR] 정념 게이지의 최대치.
## [EN] Maximum value of the passion gauge.
const PARTNER_MAX_ERO_GAUGE := 200
## [KR] 챕터 번호를 키로, 해당 챕터에서의 파트너 레벨 상한을 값으로 갖는 딕셔너리.
## [EN] Dictionary with chapter number as key and partner level cap for that chapter as value.
const PARTNER_CHAPTER_LIMIT_LEVEL :Dictionary = {
	1 : 2,
	2 : 3,
	3 : 4,
	4 : 5,
	5 : 7,
	6 : PARTNER_MAX_LEVEL
}
## [KR] 코니알의 최대 호감도 레벨.
## [EN] Konial's maximum affection level.
const NPC_MAX_LEVEL_KONIAL = 3
## [KR] 집사의 최대 호감도 레벨.
## [EN] Butler's maximum affection level.
const NPC_MAX_LEVEL_BUTLER = 2

## [KR] ──── 경험치 · 호감도 · 정념 보상 수치 ────
## 스테이지 클리어 및 H 이벤트에서 사용되는 보상 관련 기본값.
## [EN] ──── EXP · Affection · Passion reward values ────
## Default values for rewards used in stage clears and H events.

## [KR] 스테이지 클리어 시 획득하는 기본 경험치.
## [EN] Base EXP gained on stage clear.
const BASE_CLEAR_EXP: int = 20
const LOVE_LEVEL_UP_BONUS_TICKET: int = 50 # [KR] 호감도 레벨 업 시 드랍하는 티켓 값 (50*2개) / [EN] Ticket value dropped on affection level up (50*2)
const BASE_INCRESE_ERO_GAUGE = 10 # [KR] 스테이지 클리어시 증가하는 정념의 기본값 / [EN] Base passion increase on stage clear
const INCRESE_LOVE_EXP_KONIAL = 10 # [KR] 팔찌를 착용하고 스테이지 클리어시 획득하는 코니알의 호감도 기본값 / [EN] Base Konial affection gained on stage clear with bracelet equipped
const INCRESE_LOVE_EXP_NUM_BUTLER = 10 # [KR] 상자 오픈시 획득하는 집사의 호감도 갯수 / [EN] Number of butler affection gained on box open
const INCRESE_LOVE_EXP_BUTLER = 4 # [KR] 상자 오픈시 획득하는 집사의 호감도 수치 / [EN] Butler affection value gained on box open
const ERO_GAUGE_STACK_BASE := 2.0 # [KR] H하는 동안 쌓인 정념에서 환산되는 게이지 / [EN] Gauge converted from passion accumulated during H
const ERO_GAUGE_ADD_STACK_SPD := 1.8 # [KR] 해당 아이템 장착중일시 감소 속도 보너스 값 / [EN] Reduction speed bonus value when item is equipped

## [KR] ──── 보너스 티켓 ────
## 시간제한 아이템 및 스테이지 클리어 시 지급되는 보너스 티켓 수량.
## [EN] ──── Bonus tickets ────
## Bonus ticket amounts granted for time-limited items and stage clears.
const BONUS_TICKET_TIME_RIMIT := 30 # [KR] 시간제한 아이템의 보너스 티켓 / [EN] Bonus ticket for time-limited item
const BONUS_TICKET_CLEAR_ITEM := 24 # [KR] 스테이지 클리어시 보너스 티켓 / [EN] Bonus ticket on stage clear
## [KR] 호감도 보너스 기본값.
## [EN] Base affection bonus value.
const LOVE_BONUS := 10
## [KR] 코니알 전용 호감도 보너스. 코니알의 경험치통(150~230)이 레이나·마이(600~850)보다
## 작아 LOVE_BONUS(10)를 그대로 주면 과하므로, 통 크기에 비례해 축소한 값(약 10×190/700).
## [EN] Konial-specific affection bonus, scaled down proportionally to Konial's smaller exp pools.
const KONIAL_LOVE_BONUS := 3

## [KR] ──── NPC 상태 ────
## NPC의 행동 상태를 나타내는 정수 상수. 애니메이션 및 AI 분기에 사용된다.
## [EN] ──── NPC states ────
## Integer constants representing NPC behavior states. Used for animation and AI branching.
const STATE_NORMAL = 0
const STATE_EVENT = 1
const STATE_RAPE = 2
const STATE_FIND_FAILED = 3
const STATE_DONT_MOVE = 4
const STATE_RAPE_FAILED = 5 # [KR] 귀신 스테이지에서 실패한 채로 넘어가는 상태, idle 애니메이션으로 변하지 않음 / [EN] State when passing ghost stage in failure, does not change to idle animation

## [KR] 자동 저장에 사용되는 슬롯 시작 인덱스.
## [EN] Starting slot index used for auto-save.
const AUTO_SAVE_INDEX := 99
## [KR] 자동 저장 슬롯 수. AUTO_SAVE_INDEX부터 연속 슬롯을 사용한다.
## [EN] Number of auto-save slots. Uses consecutive slots starting from AUTO_SAVE_INDEX.
const AUTO_SAVE_SLOT_COUNT := 4

## [KR] cum_ef 이펙트를 재생하지 않는 예외 씬 목록. {npc_name: [event_num, ...]} 형태.
## [EN] Exception scenes that skip cum_ef effect. Format: {npc_name: [event_num, ...]}.
const CUM_EF_SKIP_SCENES := {
	NpcTypes.REINA: [7]
}

## [KR] ──── 티켓 등급별 가치 ────
## 티켓 종류에 따른 가치 배율. 획득·소비 연산에 사용된다.
## [EN] ──── Ticket value by grade ────
## Value multipliers by ticket type. Used for acquisition and consumption calculations.
const TICKET_VALUE_TRASH := 1
const TICKET_VALUE_NORMAL := 2
const TICKET_VALUE_GOLD := 3
const TICKET_VALUE_PLATINUM := 4

## [KR] 칸칸네비에서 설정 가능한 노선의 최대 갯수.
## [EN] Maximum number of routes configurable in Kankan navi.
const MAX_ROUTE_COUNT := 7 # [KR] 칸칸네비 노선 최대 설정 갯수 / [EN] Max configurable routes in Kankan navi

## [KR] ──── 퀘스트라인 키 ────
## 스토리 진행 분기를 판별하는 퀘스트라인 문자열 키.
## 각 키는 특정 이벤트 완료 여부를 체크하거나 기능 해금 조건으로 사용된다.
## [EN] ──── Questline keys ────
## Questline string keys for story progression branching.
## Each key checks event completion or is used as unlock condition.
const QUESTLINE_KANKANNAVI_GET := "chapter4_kankannavi" # [KR] 칸칸네비 기능 해금 / [EN] Kankan navi feature unlock
const QUESTLINE_BUTLER_HUMAN := "chapter4_butler3" # [KR] 이 이벤트 이후부터 집사가 인간으로 변경 / [EN] Butler changes to human after this event
const QUESTLINE_BUTLER_LOVE_QUEST_START := "butler_love_quest_start" # [KR] 집사 분실물 획득 퀘스트 시작 / [EN] Butler lost item acquisition quest start
const QUESTLINE_KANKANNAVI_UPGRADE := "chapter4_kankannavi" # [KR] 칸칸네비 기능 업그레이드(노선 구매 가능) / [EN] Kankan navi upgrade (route purchase enabled)
const QUESTLINE_KANKANNAVI_UNHIDE_TITLE := "chapter5_start" # [KR] 칸칸네비 기능 업그레이드(노선 구매 가능) / [EN] Kankan navi upgrade (route purchase enabled)

const QUESTLINE_KONIAL_BIND := "chapter6_start" # [KR] 이 이벤트 이후부터 코니알이 시작 지점에 구속됨 / [EN] Konial bound to start point after this event
const QUESTLINE_GET_ENGINE_ROOM := "konial_love_0" # [KR] 엔진 룸 힌트 획득하는 대화 이후


## [KR] [enum NpcTypes]를 키로 하여 각 NPC의 SD 아이콘 텍스처를 매핑하는 딕셔너리.
## [EN] Dictionary mapping [enum NpcTypes] to each NPC's SD icon texture.
const SD_ICONS := {
	NpcTypes.REINA: preload("res://resources/ui/icons/sd_icon/reina.png"),
	NpcTypes.MAI: preload("res://resources/ui/icons/sd_icon/mai.png"),
	NpcTypes.KONIAL: preload("res://resources/ui/icons/sd_icon/konial.png"),
	NpcTypes.PAZUZU: preload("res://resources/ui/icons/sd_icon/pazuzu.png"),
	NpcTypes.BUTLER: preload("res://resources/ui/icons/sd_icon/butler.png"),
}
const UNKNOWN_SD_ICON:= preload("res://resources/ui/icons/sd_icon/Unknown.png")

## [KR] H 이벤트 버블의 활성/비활성 상태를 나타내는 열거형.
## [EN] Enum representing H event bubble active/inactive state.
enum HBubble {EVENT_OFF, EVENT_ON}
## [KR] [enum HBubble] 상태별 버블 텍스처를 매핑하는 딕셔너리.
## [EN] Dictionary mapping [enum HBubble] states to bubble textures.
const H_EVENT_BUBBLES := {
	HBubble.EVENT_OFF: preload("res://resources/ui/GameScreen/h_event_bubble_base.png"),
	HBubble.EVENT_ON: preload("res://resources/ui/GameScreen/h_event_bubble_base_can_event.png")
}

## [KR] ──── UI 아이콘 리소스 ────
## 게임 내 UI에 표시되는 아이콘 텍스처 프리로드 모음.
## [EN] ──── UI icon resources ────
## Preloaded icon textures displayed in game UI.

## [KR] 사랑의 팔찌 아이콘.
## [EN] Love bracelet icon.
const LOVE_BRACELET_ICON = preload("res://resources/ui/icons/icons15.png")

## [KR] 티켓 등급별 아이콘.
## [EN] Icons by ticket grade.
const TICKET_TRASH_ICON = preload("res://resources/ui/ticket_trash_icon.png")
const TICKET_ICON = preload("res://resources/ui/ticket_icon.png")
const TICKET_GOLD_ICON = preload("res://resources/ui/ticket_gold_icon.png")
const TICKET_PLATINUM_ICON = preload("res://resources/ui/ticket_platinum_icon.png")
## [KR] 집사 하트 아이콘.
## [EN] Butler heart icon.
const HEART_BUTLER_ICON = preload("res://resources/ui/butler_heart.png")

## [KR] 기타 시스템 아이콘.
## [EN] Other system icons.
const ROUTE_COIN_ICON = preload("res://resources/ui/icons/icons25.png")
const ANO_H_ITEM_ICON = preload("res://resources/ui/icons/icons23.png")
const NPC_H_ITEM_ICON = preload("res://resources/ui/icons/icons22.png")
const INVENTORY_ICON = preload("res://resources/ui/icons/icons17.png")

## [KR] ──── 단축키 액션 이름 ────
## [code]InputMap[/code]에 등록된 단축키 액션 문자열.
## [EN] ──── Shortcut action names ────
## Shortcut action strings registered in [code]InputMap[/code].
const TRAIN_KEY_KANKANNAVI := "shotcut_kankan"
const TRAIN_KEY_INVENTORY := "shotcut_inventory"

## [KR] ──── 윈도우 상태 키 ────
## UI 윈도우의 열림/닫힘 상태를 관리하기 위한 문자열 키.
## 동시에 열리면 안 되는 팝업 간 충돌 방지에 사용된다.
## [EN] ──── Window state keys ────
## String keys for managing UI window open/close state.
## Used to prevent conflicts between popups that must not open simultaneously.
const WINDOW_STATE_STAGE_CHANGING := "stage_changing"
const WINDOW_STATE_SHOP_OPEN := "shop_open"
const WINDOW_STATE_H_ACTION := "h_action"
const WINDOW_STATE_SAFE_STAGE_H_ACTION := "safe_stage_h_action"
const WINDOW_STATE_PAUSE_MENU := "pause_menu_open"
const WINDOW_KANKAN_OPEN := "kankan_open"
const WINDOW_INVEN_OPEN := "inven_open"
const WINDOW_STATE_BUG_REPORTER := "bug_reporter_open"

## [KR] ──── 비대화 음성 데이터 ────
## 대화창 없이 재생되는 음성 데이터의 JSON 경로 및 파싱 결과.
## [EN] ──── Non-dialogue voice data ────
## JSON path and parsed result for voice data played without dialogue window.
const UNDIALOGUE_TALK_JSON_PATH := "res://Gameplay/GameData/undialogue_voice_json.json"
static var UNDIALOGUE_TALK_DATA: Dictionary = (preload("res://Gameplay/GameData/undialogue_voice_json.json") as JSON).data
