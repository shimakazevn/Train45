## [KR] GodotSteam 초기화 및 도전과제/스탯 통신을 담당하는 래퍼 오토로드.
## [br]GodotSteam이 설치되지 않았거나 초기화에 실패하면 모든 호출을 무해하게 무시한다.
## [br]Steam 전역 식별자를 직접 참조하지 않고 [method Engine.get_singleton]으로 동적 접근하므로,
## GodotSteam 미설치 상태에서도 스크립트가 정상 파싱·실행된다.
extends Node

## [KR] Steam API 사용 가능 여부. false면 모든 도전과제 호출이 no-op.
var is_enabled: bool = false

## [KR] 디버그 로그 모드. true면 실제 해금 대신 의도된 해금을 콘솔에 출력한다. (로직 테스트용)
var _debug_log: bool = false

## [KR] 디버그/로그 모드에서 해금 요청된 도전과제 API 이름 누적 기록. (자동 검증·QA 확인용)
var debug_unlocked: Array[String] = []

## [KR] GodotSteam 싱글톤 참조. 미설치 시 null.
var _steam = null

func _ready() -> void:
	# [KR] 디버그 빌드에서는 실제 해금은 막고 로그 모드로 전환 (실수 해금 방지 + 판정 검증)
	if Constants.IS_DEBUG:
		_debug_log = true
		print("[Steam] Debug build - real unlocks disabled, log mode ON")
		return

	if not Engine.has_singleton("Steam"):
		print("[Steam] GodotSteam not installed - achievements disabled")
		return

	_steam = Engine.get_singleton("Steam")

	# [KR] steamInitEx 반환 형식: { status: int, verbal: String }, status 0 == 정상
	# [KR] GodotSteam 버전에 따라 steamInit()일 수 있으니 빌드에 맞게 확인할 것.
	var result = _steam.steamInitEx()
	if typeof(result) == TYPE_DICTIONARY and result.get("status", -1) == 0:
		is_enabled = true
		print("[Steam] Initialization succeeded: ", _steam.getPersonaName())
	else:
		push_warning("[Steam] 초기화 실패: %s" % [result])

func _process(_delta: float) -> void:
	# [KR] GDExtension 빌드에 따라 수동 콜백이 필요할 수 있음 (메서드 존재 시에만 호출)
	if _steam and _steam.has_method("run_callbacks"):
		_steam.run_callbacks()

## [KR] [param api_name] 도전과제를 해금한다. 이미 해금된 경우 통신을 생략한다.
func unlock(api_name: String) -> void:
	if not is_enabled:
		if _debug_log:
			if not debug_unlocked.has(api_name):
				debug_unlocked.append(api_name)
			print("[Steam][DEBUG] Scheduled to unlock: ", api_name)
		return
	var ach = _steam.getAchievement(api_name)
	if typeof(ach) == TYPE_DICTIONARY and ach.get("achieved", false):
		return
	_steam.setAchievement(api_name)
	_steam.storeStats()
	print("[Steam] Achievement unlocked: ", api_name)

## [KR] 모든 스탯과 도전과제를 초기화한다. (개발/테스트 전용)
## [br]현재 Steam 계정의 해당 appid 데이터를 즉시 리셋한다.
func reset_all() -> void:
	if not is_enabled:
		push_warning("[Steam] 비활성 상태 - 초기화 불가 (디버그 빌드이거나 미연동)")
		return
	_steam.resetAllStats(true)  # [KR] true = 도전과제도 함께 초기화
	_steam.storeStats()
	print("[Steam] All stats/achievements reset complete")
