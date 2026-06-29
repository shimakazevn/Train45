extends GutTest
## 번역 키 회귀 테스트.
##
## Bug(리포트 #29): UI에 'MORE_FRIENDLY_MAI' 같은 원시 번역 키 문자열이 그대로 노출됨.
## Fix: UI_Text_Translations에 해당 키를 추가하여 tr()이 정상 문자열로 해결되도록 함.
##
## 전략: 게임 코드가 참조하는 핵심 UI 키가 TranslationServer에서 해결되는지 검증한다.
##       tr(key) == key 이면 키가 누락/오타로 해결되지 않아 원시 키가 노출되는 상태이다.

# 게임 코드에서 NotionEvent 등으로 직접 참조하는 키. 누락 시 원시 키가 UI에 노출된다.
const REQUIRED_UI_KEYS := [
	"MORE_FRIENDLY_MAI",
	"MORE_FRIENDLY_REINA",
]

var _prev_locale: String

func before_all() -> void:
	_prev_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("ko")

func after_all() -> void:
	TranslationServer.set_locale(_prev_locale)

func test_required_ui_keys_resolve() -> void:
	for key in REQUIRED_UI_KEYS:
		var translated := tr(key)
		assert_ne(translated, key,
			"'%s' 번역 키가 해결되어야 한다 (원시 키 노출 방지, #29)" % key)
