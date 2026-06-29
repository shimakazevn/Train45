extends Node2D
class_name GhostHAnomaly

signal end_ghost_h
signal start_h

@export var ghost_sprite: Sprite2D
@export var ghost_anim: AnimationPlayer
@export var player: Player
## [KR] action 중 재생할 신음 보이스 루프(선택). 할당된 컴포넌트만 신음이 난다.
@export var moan_stream: HMoanStream
@onready var h_area: Area2D = $HArea
@onready var keyboard_icon: TextureRect = $KeyboardIcon
## [KR] 절정 게이지 위젯(표시/숨김·흔들림). action_progress 인스턴스 루트(Base).
@onready var climax_progress_base: Sprite2D = $ActionProgressBase
## [KR] 절정 게이지 바(값). 위젯 내부 바. 값이 클수록 Base가 붉어진다(증가 게이지).
@onready var climax_progress: TextureProgressBar = $ActionProgressBase/ActionProgressBar
@onready var love_effect: CPUParticles2D = $LoveEffect


@export var climax_life_max: float = 900.0
var climax_life: float = climax_life_max # 절정 게이지
@export var ticket_total: int = 120
var ticket_n: int = 20 #n등분 지점마다 드롭
var dropped_sections: int = 0 #지금까지 몇번 드롭했는지

var current_state: GhostState
enum GhostState {NOT_FIND, IN, AFTER_FIND, ACTION, CUM, AFTER_CUM}
const STATE_ANIM_NAME := {
	GhostState.NOT_FIND : "not_find",
	GhostState.IN : "in",
	GhostState.AFTER_FIND : "after_find",
	GhostState.ACTION : "action",
	GhostState.CUM : "cum",
	GhostState.AFTER_CUM : "after_cum"
}

func _ready() -> void:
	check_npc() ##현재 지정된 파트너 타입이 아닐 경우 해당 노드를 삭제함
	
	player.player_ghost_sex.connect(_on_ghost_sex)
	GameEvents.stage_clear.connect(_on_stage_clear)
	h_area.area_entered.connect(_on_body_entered)
	h_area.area_exited.connect(_on_body_exited)
	ghost_anim.animation_finished.connect(_on_anim_finished)
	
	set_sprite_random()
	keyboard_icon.hide()
	climax_progress_base.hide()
	current_state = GhostState.NOT_FIND
	ghost_anim.play(STATE_ANIM_NAME[current_state])
	h_area.monitorable = false
	
	climax_progress.max_value = climax_life_max
	climax_progress.value = 0.0 # 게이지는 0에서 시작해 차오른다(증가 방식)
	
	love_effect.emitting = false

##시작할때 스프라이트 세팅, 바리에이션이 있을 경우를 위해 오버라이드 함수로 남겨놓음
func set_sprite_random():
	pass

## 동행 파트너가 정해져 있는지 검사하는 오버라이드 함수
func check_npc():
	pass

##파트너 h 아노말리 컴포넌트에서는 빈칸으로 두는 오버라이드 함수
func set_near_npc_position():
	var near_npc = h_area.get_overlapping_bodies()
	for body in near_npc:
		if body is Npc:
			if body.position.x >= 960: # [KR] 맵의 중앙 기준 / [EN] Based on map center
				body.position.x -= 150
			else:
				body.position.x += 150

func _process(_delta: float) -> void:
	if current_state == GhostState.ACTION:
		climax_life = maxf(0.0, climax_life - 1)
		climax_progress.value = climax_life_max - climax_life # 내부 life는 감소하지만 게이지는 차오르게 표시
		
		# 남은 life 비율
		var ratio: float = climax_life / climax_life_max
		# 분포 함수 (뒤로 갈수록 몰림)
		var curved_progress: float = pow(1.0 - ratio, 3) # 제곱 분포
		# 현재 몇 번째 구간에 들어왔는지
		var current_section: int = int(floor(curved_progress * ticket_n))
		
		# 애니메이션 속도 (life가 줄수록 1.0 → 1.5로 증가)
		ghost_anim.speed_scale = lerp(1.7, 0.8, ratio)
		
		#print("ratio: %d, current section: %d"%ratio, current_section)
		
		# 새 구간에 진입했으면 티켓 드롭
		if current_section > dropped_sections:
			ticket_drop()
			dropped_sections = current_section
		
		if climax_life <= 0.0:
			if ghost_anim.current_animation != "action_climax":
				ghost_anim.play("action_climax")
	else:
		ghost_anim.speed_scale = 1.0

func _on_ghost_sex(state: bool):
	if state == true:
		player.position.x = ghost_sprite.global_position.x
		set_state_change(GhostState.ACTION)
	else:
		if climax_life > 0.0:
			set_state_change(GhostState.AFTER_FIND)
		else:
			set_state_change(GhostState.CUM)
			

func _on_stage_clear():
	set_near_npc_position()
	set_state_change(GhostState.IN)
	h_area.monitorable = true
	set_to_stage_clear()

## 스테이지 클리어시 호출하는 오버라이드 함수
func set_to_stage_clear():
	pass

func set_state_change(state: GhostState):
	if current_state == state:
		return
	# [KR] action에서 벗어날 때 신음 처리:
	#  - CUM(절정)으로 가면 soft_stop: 진행 중 클립은 절정 연출 동안 마저 재생되게 둔다.
	#  - 그 외(중단 → AFTER_FIND)면 stop_now: 즉시 끊는다(중간에 그만뒀는데 신음이 이어지는 버그 방지).
	if current_state == GhostState.ACTION and moan_stream:
		if state == GhostState.CUM:
			moan_stream.soft_stop()
		else:
			moan_stream.stop_now()

	match state:
		GhostState.IN:
			if current_state == GhostState.NOT_FIND:
				# 클리어 ui가 꺼질때쯤에 애니메이션을 재생한다
				ghost_anim.play(STATE_ANIM_NAME[state])
				ghost_anim.seek(0.0, true)
				ghost_anim.pause()
				await get_tree().create_timer(2.5).timeout
				if equip_item_check_override():
					GameEvents.emit_call_tutorial(TutoManager.TUTO_GHOST_H) #최초 튜토리얼 출력
				
		GhostState.AFTER_FIND:
			if equip_item_check_override():
				keyboard_icon.show()
				love_effect.emitting = true
			else:
				need_item_notion_override()
		GhostState.ACTION:
			start_h.emit()
			if moan_stream:
				moan_stream.start_loop()
			if not climax_progress_base.visible:
				climax_progress_base.show()
			keyboard_icon.show() # 액션 중에도 입력 안내 유지
			love_effect.emitting = false
		GhostState.CUM:
			climax_progress_base.hide()
			keyboard_icon.hide()
		GhostState.AFTER_CUM:
			# [KR] H 종료 상태: 절정 연출 동안 남아 재생되던 신음 꼬리까지 확실히 정지.
			if moan_stream:
				moan_stream.stop_now()
			end_ghost_h.emit()
	
	ghost_anim.play(STATE_ANIM_NAME[state])
	current_state = state
	

func _on_body_entered(area):
	if area is TalkArea:
		near_player(true)

func _on_body_exited(area):
	if area is TalkArea:
		near_player(false)

func ticket_drop():
	var drop_amount:int = int(float(ticket_total) / ticket_n)
	GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, drop_amount)
	set_progress_bar_tween()
	#print(drop_amount)

func near_player(state: bool):
	if current_state == GhostState.AFTER_FIND:
		var target_scale: float
		if state:
			target_scale = 1.2
		else:
			target_scale = 1.0
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(keyboard_icon, "scale", Vector2(target_scale, target_scale), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_anim_finished(anim_name: String):
	match anim_name:
		STATE_ANIM_NAME[GhostState.IN]:
			set_state_change(GhostState.AFTER_FIND)
		STATE_ANIM_NAME[GhostState.CUM]:
			set_state_change(GhostState.AFTER_CUM)

func set_progress_bar_tween():
	var tween: Tween = get_tree().create_tween()
	var rand_dist: float = 4.0
	var rand_position: Vector2 = Vector2(randf_range(-rand_dist, rand_dist), randf_range(-rand_dist, rand_dist))
	tween.tween_property(climax_progress, "self_modulate", Color.WHITE, 0.5).from(Color.AQUAMARINE)
	tween.set_parallel()
	# [KR] 흔들림은 위젯 전체(Base)에. Base의 self_modulate는 위젯 스크립트가 매 프레임 제어하므로 건드리지 않는다.
	tween.tween_property(climax_progress_base, "position", climax_progress_base.position, 0.2).from(climax_progress_base.position + rand_position)

func equip_item_check_override()->bool:
	if MetaProgression.has_equipment("ghost_ano_h"):
		return true
	return false

func need_item_notion_override():
	NotionEvent.notion("NOTI_UNEQUIP_ITEM", Constants.ANO_H_ITEM_ICON, Color.BLACK)
