## UI 효과음 재생을 위한 기본 오디오 스트림 플레이어.
## 미리 로드된 UI 사운드 상수를 제공하며, 랜덤 피치 기능을 지원한다.
extends AudioStreamPlayer
class_name UiSoundStreamPlayer

## 메뉴 닫기 효과음.
static var SOUND_MENU_OUT = load("res://sound/sfx/ui/paper_flip1.wav")
## 메뉴 열기 효과음.
static var SOUND_MENU_IN = load("res://sound/sfx/ui/paper_flip2.wav")

## 옵션 버튼 포커스 효과음.
static var SOUND_OPTION_BUTTON_FOCUS = load("res://sound/sfx/ui/option_button_focus.wav")
## 옵션 페이지 진입 효과음.
static var SOUND_OPTION_PAGE_IN = load("res://sound/sfx/ui/paper_flip3.wav")
## 옵션 페이지 퇴장 효과음.
static var SOUND_OPTION_PAGE_OUT = load("res://sound/sfx/ui/paper_flip4.wav")

## 칸칸 루트 삭제 효과음.
static var SOUND_KANKAN_ROUTE_ERASE = load("res://sound/sfx/ui/kankan_route_erase.wav")
## 칸칸 열기 효과음.
static var SOUND_KANKAN_ON = load("res://sound/sfx/ui/kankan_on.wav")
## 칸칸 닫기 효과음.
static var SOUND_KANKAN_OFF = load("res://sound/sfx/ui/kankan_exit.wav")

static var SOUND_KANKAN_DESTINATION_CORECT = load("res://sound/sfx/ui/kankan_destination_find.wav")

## 인벤토리 아이템 장착 불가 효과음.
static var SOUND_INVEN_ITEM_DONT_EQUIP = load("res://sound/sfx/ui/inven_item_dont_equip.wav")
## 인벤토리 아이템 장착 효과음.
static var SOUND_INVEN_ITEM_EQUIP = load("res://sound/sfx/ui/inven_item_equip.wav")
## 인벤토리 닫기 효과음.
static var SOUND_INVEN_OFF = load("res://sound/sfx/ui/inven_off.wav")
## 인벤토리 열기 효과음.
static var SOUND_INVEN_ON = load("res://sound/sfx/ui/inven_on.wav")

## 상점 닫기 효과음.
static var SOUND_SHOP_OFF = load("res://sound/sfx/ui/shop_off.wav")
## 상점 열기 효과음.
static var SOUND_SHOP_ON = load("res://sound/sfx/ui/shop_on.wav")
## 상점 구매 효과음.
static var SOUND_SHOP_BUY = load("res://sound/sfx/ui/shop_buy.wav")
## 상점 구매 불가 효과음 (품절 또는 티켓 부족).
static var SOUND_SHOP_CANT_BUY = load("res://sound/sfx/ui/kankan_route_focus.wav")

static var SOUND_LOVE_BUBBLE_OK = load("res://sound/sfx/ui/LoveBubbleOk.mp3")
static var SOUND_LOVE_BUBBLE_NO = load("res://sound/sfx/ui/LoveBubbleNo.mp3")

static var GET_BUTLER_HEART = load("res://sound/sfx/ui/get_butler_heart.mp3")
static var GET_TICKET = load("res://sound/sfx/ui/get_ticket.mp3")

static var ABNORMALITY_FOUND = load("res://sound/sfx/Abnormality_found.mp3")
static var ABNORMALITY_NEW = load("res://sound/sfx/Abnormality_new.mp3")
static var ABNORMALITY_NOT_FOUND = load("res://sound/sfx/Abnormality_not_found.mp3")
## 이변 탐지에 실패해 기회를 1 잃었을 때(LIFE_UP 아이템 장착 중 첫 실패) 효과음.
static var FAIL_TO_FIND_ABNORMALITY = load("res://sound/sfx/fail_to_find_abnormality.mp3")
## 이변 탐지 실패로 생명이 모두 소진되어 첫 차량(시작 지점)으로 복귀할 때 노이즈 효과음.
static var RETURN_TO_START_POINT = load("res://sound/sfx/return_to_start_point.mp3")

## 서큐버스가 손전등 빛에 데미지를 입을 때 효과음.
static var DAMAGE_TO_SUCCUBUS = load("res://sound/sfx/damage_to_succubus.mp3")
## 서큐버스가 처치되어 소멸할 때 효과음.
static var FADING_SUCCUBUS = load("res://sound/sfx/fading_succubus.mp3")
## 손전등 소등 효과음(몇 번 깜빡이다 꺼지는 느낌).
static var SWITCH_OFF = load("res://sound/sfx/switch_off.mp3")
## 손전등 점등 효과음.
static var SWITCH_ON = load("res://sound/sfx/switch_on.mp3")

## 룰렛 바닥 버튼을 밟았을 때 「카チッ」 클릭음.
static var ROULETTE_ON = load("res://sound/sfx/roulette_on.mp3")
## 룰렛 3칸이 모두 맞춰졌을 때 화려한 효과음.
static var ROULETTE_777 = load("res://sound/sfx/roulette_777.mp3")


## [code]true[/code]이면 재생 시 피치를 랜덤으로 변경한다.
@export var randomize_pitch = true
## 랜덤 피치 최소값.
@export var min_pitch = .9
## 랜덤 피치 최대값.
@export var max_pitch = 1.1

## 지정된 [param target_stream]을 재생한다. [member randomize_pitch]가 활성화되어 있으면 피치를 랜덤 조정한다.
func set_stream_play_to_file(target_stream: AudioStream):
	if target_stream == null:
		return
	if randomize_pitch:
		pitch_scale = randf_range(min_pitch, max_pitch)
	else:
		pitch_scale = 1

	stream = target_stream
	play()

## [param streams] 배열에서 무작위로 하나를 선택하여 재생한다.
## 배열이 비어있거나 [code]null[/code]이면 아무 동작도 하지 않는다.
func set_stream_play(streams: Array[AudioStream]):
	if streams == null or streams.size() == 0:
		return

	var play_stream = streams.pick_random()

	set_stream_play_to_file(play_stream)
