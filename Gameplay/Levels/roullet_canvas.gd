extends CanvasLayer

@export var event_component: EventComponent
@export var roullets: Array[Node2D]
@export var slots: Array[TextureRect]
@export var slot_texture: Array[CompressedTexture2D]
@export var gift_anim: AnimationPlayer
@onready var roullet_container: HBoxContainer = $RoulletContainer

var result : Array[int] = []
var tween : Tween

enum {T_LUCKY, T_KONIAL, T_BUNNY}

func _ready() -> void:
	roullets[0].slot_stop.connect(_on_roullet_stop)
	roullets[1].slot_stop.connect(_on_roullet_stop)
	roullets[2].slot_stop.connect(_on_roullet_stop)
	
func _on_roullet_stop(current_count: int):
	if result.size() < 3:
		result.append(current_count)
	for i in range(slots.size()):
		if slots[i].texture == null:
			slots[i].texture = slot_texture[current_count]
			break
			
	if result.size() == 3:
		check_result()

func check_result():
	# 3칸이 모두 같은 문양이면 화려한 효과음 (어떤 문양이든)
	if result[0] == result[1] and result[1] == result[2]:
		SoundManager.play_sfx(UiSoundStreamPlayer.ROULETTE_777)
	tween = create_tween()
	tween.tween_property(roullet_container, "scale", Vector2.ZERO, 1.0)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(set_result)

func set_result():
	var _jackpot: bool = true
	var _bunny: bool = true
	var _ticket: int = 0
	for i in result:
		if i != T_LUCKY:
			_jackpot = false
		if i != T_BUNNY:
			_bunny = false
		
		match i:
			T_LUCKY:
				_ticket += 20
			T_BUNNY:
				_ticket += 6
				
	
	if _jackpot:
		_ticket = 150
	
	GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, _ticket*Constants.TICKET_VALUE_NORMAL)

	if _bunny: ## 토끼 문양 세개일 경우 바니걸 이벤트
		GameEvents.emit_stage_clear()
		gift_anim.play("gift")
		# 마이가 아닐시 시작 지점으로 귀환
		event_component.not_matching_partner_return_base(Constants.NpcTypes.MAI)
		
	else:
		await get_tree().create_timer(8.0).timeout
		GameEvents.emit_game_complete()
