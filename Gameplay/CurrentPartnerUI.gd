extends TextureRect
## [KR] 현재 파트너의 호감도 UI를 관리하는 [code]TextureRect[/code].
## [EN] [code]TextureRect[/code] that manages the current partner's affection UI.
## [KR] 파트너의 SD 아이콘, 호감도 경험치 바, 레벨 표시 및 레벨업 연출을 담당한다.
## [EN] Handles partner's SD icon, affection experience bar, level display, and level-up effects.

## [KR] 파트너별 SD 아이콘 텍스처 배열
## [EN] Array of SD icon textures per partner
@export var sd_icons : Array[CompressedTexture2D]
## [KR] 하이라이트 셰이더 [ColorRect]
## [EN] Highlight shader [ColorRect]
@export var highlight_shader: ColorRect

## [KR] 호감도 경험치 프로그레스 바
## [EN] Affection experience progress bar
@onready var love_progress_bar = %LoveProgressBar
## [KR] 호감도 레벨 텍스트 [Label]
## [EN] Affection level text [Label]
@onready var love_level = %LoveLevel
## [KR] UI 애니메이션 플레이어
## [EN] UI animation player
@onready var animation_player = $AnimationPlayer
## [KR] 목표 경험치를 표시하는 흰색 바
## [EN] White bar displaying target experience
@onready var white_bar = %WhiteBar
## [KR] 레벨업 애니메이션 플레이어
## [EN] Level-up animation player
@onready var love_level_anim = %LoveLevel/LoveLevelAnim
## [KR] 호감도 이펙트 파티클
## [EN] Affection effect particles
@onready var love_effect : CPUParticles2D = %LoveEffect

## [KR] 파트너 매니저 참조
## [EN] Partner manager reference
@export var partner_manager: PartnerManager

## [KR] 현재 프로그레스 바 값
## [EN] Current progress bar value
var current_value = 0.0  # [KR] 현재 프로그레스 바 값 (float) / [EN] Current progress bar value (float)
## [KR] 목표 프로그레스 바 값
## [EN] Target progress bar value
var target_value = 0.0  # [KR] 목표 값 (float) / [EN] Target value (float)
## [KR] 보간 속도 계수
## [EN] Interpolation speed coefficient
var fill_speed = 2  # [KR] 보간 속도 / [EN] Interpolation speed

## [KR] 초기화 시 [PartnerManager]의 시그널을 연결하고 NPC 레벨업 이벤트를 구독한 후 UI를 업데이트한다.
## [EN] On initialization, connects [PartnerManager] signals, subscribes to NPC level-up events, and updates the UI.
func _ready():
	partner_manager.ready.connect(_on_partner_manager_ready)
	partner_manager.partner_change.connect(_on_partner_change)
	for i in partner_manager.partner:
		var _npc = i as Npc
		_npc.love_level_up_event.connect(_on_npc_level_up)
	love_progress_bar.value = current_value
	ui_update()

## [KR] [PartnerManager] 준비 완료 시 UI를 업데이트한다.
## [EN] Updates UI when [PartnerManager] is ready.
func _on_partner_manager_ready():
	ui_update()


## [KR] 매 프레임 [member current_value]를 [member target_value]에 보간하여 프로그레스 바를 부드럽게 업데이트한다.
## [EN] Interpolates [member current_value] towards [member target_value] every frame to smoothly update the progress bar.
func _process(_delta):
	# [KR] 목표 값에 다가가도록 서서히 보간
	# [EN] Gradually interpolate towards target value
	if abs(current_value - target_value) > 0.3:  # [KR] 목표 값에 거의 도달할 때까지 업데이트 / [EN] Update until nearly reaching target value
		animation_player.play("get_exp")
		current_value = lerp(current_value, target_value, fill_speed * _delta)
		love_progress_bar.value = current_value
	else :
		if animation_player.current_animation == "get_exp":
			animation_player.play("RESET")
		


## [KR] 파트너 변경 시 UI를 업데이트한다.
## [EN] Updates UI on partner change.
func _on_partner_change(_npc_type: int):
	ui_update()

## [KR] 현재 파트너의 SD 아이콘, 레벨, 경험치 바를 갱신한다.
## [EN] Updates the current partner's SD icon, level, and experience bar.
## [KR] 최대 레벨 도달 시 [method set_max_level_ui]를 호출한다.
## [EN] Calls [method set_max_level_ui] when max level is reached.
func ui_update():
	if partner_manager.current_partner < 3:
		var current_partner = partner_manager.partner[partner_manager.current_partner] as Npc
		
		# [KR] 레벨 텍스트는 즉시 업데이트
		# [EN] Level text is updated immediately
		self.texture = sd_icons[current_partner.npc_name]
		love_level.text = str(current_partner.love_level)
		
		if current_partner.love_level >= Constants.PARTNER_MAX_LEVEL:
			set_max_level_ui(current_partner)
			love_effect.emitting = false
		else:
			# [KR] love_exp를 목표 값으로 설정 (float으로 변환)
			# [EN] Set love_exp as target value (convert to float)
			target_value = float(current_partner.love_exp)
			set_next_target_exp(current_partner.target_love_exp)
			white_bar.value = target_value
			love_effect_emit(target_value, current_partner.target_love_exp)


## [KR] [param current_partner]가 최대 레벨일 때 UI를 설정한다.
## [EN] Sets the UI when [param current_partner] is at max level.
func set_max_level_ui(current_partner: Npc):
	love_level.text = "MAX"
	target_value = float(current_partner.target_love_exp)

## [KR] NPC 레벨업 이벤트 콜백. 현재 파트너의 레벨업일 때만 UI를 갱신하고 레벨업 애니메이션을 재생한다.
## [EN] NPC level-up event callback. Only updates UI and plays level-up animation for current partner's level-up.
func _on_npc_level_up(npc_type: int):
	if npc_type != partner_manager.current_partner:
		return
	ui_update()
	love_level_anim.play("level_up")

## [KR] [param love_exp]가 [param target_love_exp] 이상이면 호감도 이펙트를 활성화한다.
## [EN] Activates the affection effect if [param love_exp] is >= [param target_love_exp].
func love_effect_emit(love_exp: float, target_love_exp: float):
	if love_exp >= target_love_exp:
		love_effect.emitting = true
	else:
		love_effect.emitting = false
	
## [KR] 다음 목표 경험치를 [param next_target_exp]로 설정하여 프로그레스 바의 최대값을 갱신한다.
## [EN] Sets the next target experience to [param next_target_exp] to update the progress bar's max value.
func set_next_target_exp(next_target_exp: int):
	white_bar.max_value = next_target_exp
	love_progress_bar.max_value = next_target_exp
