## [KR] 게임 전체의 언어(로케일) 설정을 관리하는 오토로드 싱글톤.
##
## [KR] [method set_language]로 언어를 변경하면 [code]TranslationServer[/code]의 로케일이 갱신되고,
## [KR] [signal lang_changed] 시그널을 통해 UI 등 구독자에게 변경을 알린다.
## [KR] 지원 언어: ko(한국어), jp(일본어), zh(중국어), en(영어).
## [EN] Autoload singleton that manages language (locale) settings for the entire game.
##
## [EN] Changing the language via [method set_language] updates the locale of [code]TranslationServer[/code],
## [EN] and notifies subscribers such as the UI of the change through the [signal lang_changed] signal.
## [EN] Supported languages: ko (Korean), jp (Japanese), zh (Chinese), en (English).
extends Node

## [KR] 언어가 변경되었을 때 발생하는 시그널.
## [KR] [param locale]은 새로 설정된 로케일 코드(예: "ko", "jp").
## [EN] Signal emitted when the language is changed.
## [EN] [param locale] is the newly set locale code (e.g. "ko", "jp").
signal lang_changed(locale: String)

## [KR] 현재 설정된 로케일 코드. 빈 문자열이면 아직 설정되지 않은 상태.
## [EN] Currently set locale code. Empty string means not yet configured.
var current_locale: String = ""

## [KR] 내부 언어 키 → TranslationServer에 넘길 실제 로케일 변환표.
## [KR] "zh"를 그대로 넘기면 셰이핑 엔진(HarfBuzz)이 간체 중국어(ZHS)로 해석해
## [KR] 번체 폰트의 가운데 구두점(。，)이 좌하단 간체 글리프로 치환된다.
## [KR] zh_TW로 넘겨야 번체(ZHT)로 셰이핑되어 구두점이 가운데에 온다.
## [KR] (검증: NotoSansCJKtc에서 zh→GID 1398(좌하단), zh_TW→GID 63146(가운데))
## [KR] "zh"로 등록된 번역·리소스 리맵은 언어 일치로 zh_TW 로케일에도 매칭된다.
const TRANSLATION_LOCALE_REMAP := {"zh": "zh_TW"}
#
#const THEMES := {
	#"jp": preload("res://resources/theme/theme_jp.tres"),
	#"zh": preload("res://resources/theme/theme_zh.tres"),
#}

func _ready() -> void:
	_rebrand_zh_translations()

## [KR] "zh" 로케일로 임포트된 번역 리소스들의 locale을 zh_TW로 재지정한다.
## [KR] 로케일만 zh_TW로 바꿔도 라벨(language="")의 셰이핑 언어는
## [KR] get_tool_locale() = "가장 잘 맞는 번역의 로케일"이라서 "zh"로 되돌아가
## [KR] 간체식 구두점이 유지된다. 번역 리소스 자체가 zh_TW여야 셰이핑까지 zh_TW가 전달된다.
## [KR] (CSV 열 이름을 바꾸는 방법은 Dialogic 번역 재생성 시 "zh"로 되돌아가므로 런타임에 처리)
func _rebrand_zh_translations() -> void:
	var paths: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray())
	for path in paths:
		if path.contains(".zh."):
			var tr_res: Translation = load(path)
			if tr_res and tr_res.locale == "zh":
				tr_res.locale = "zh_TW"

## [KR] 게임 언어를 변경한다.
##
## [KR] [param locale]은 설정할 로케일 코드(예: "ko", "jp", "zh", "en").
## [KR] 이미 동일한 로케일이면 변경하지 않고 무시한다.
## [KR] 변경 시 [signal lang_changed] 시그널을 발행한다.
## [EN] Changes the game language.
##
## [EN] [param locale] is the locale code to set (e.g. "ko", "jp", "zh", "en").
## [EN] If the locale is already the same, no change is made and it is ignored.
## [EN] Emits the [signal lang_changed] signal when changed.
func set_language(locale: String):
	var translation_locale: String = TRANSLATION_LOCALE_REMAP.get(locale, locale)
	if current_locale == locale and TranslationServer.get_locale() == translation_locale:
		return

	current_locale = locale
	TranslationServer.set_locale(translation_locale)

	lang_changed.emit(locale)

## [KR] 사용자가 직접 언어를 바꿀 때 호출하는 메서드.
## [KR] 로케일 변경에 더해 전역 언어 변수 갱신과 설정 파일 저장까지 수행하여,
## [KR] 옵션 메뉴/개발자 패널 등 어느 경로로 바꿔도 동작이 동일하도록 한다.
func change_language(locale: String) -> void:
	set_language(locale)
	GameEvents.current_language = locale
	ConfigFileHandler.save_video_setting("language", locale)



#func apply_theme(locale: String)-> Theme:
	#var theme: Resource = THEMES.get(locale, null)
	#
	#return theme

## [KR] 현재 설정된 로케일 코드를 반환한다.
## [EN] Returns the currently set locale code.
func get_current_locale()-> String:
	return current_locale
