extends Sprite2D

@export var player: Player
@onready var pcam: PhantomCamera2D = $PhantomCamera2D
@onready var detect_icon: Sprite2D = $DetectIcon
@onready var anim: AnimationPlayer = $AnimationPlayer
@export var current_partner_entity: CurrentNpc
@export var cat_event_component: CatEventComponent

const CAT_CAMERA_SET_DIST: float = 550.0
const CAT_DETECT_DIST: float = 450.0
const CAT_RUN_DIST: float = 250.0

var cat_run:bool = false
enum CatState {REST, IDLE, DETECT, RUN, CATCH}
var cat_state: CatState = CatState.REST

func _ready() -> void:
	detect_icon.hide()
	anim.animation_finished.connect(_on_anim_finished)

func _process(_delta):
	if player.position.distance_to(position) < CAT_CAMERA_SET_DIST and cat_state == CatState.REST:
		pcam.set_priority(100)
		cat_state = CatState.IDLE
		anim.play("idle")
		
	if player.position.distance_to(position) < CAT_DETECT_DIST and cat_state == CatState.IDLE:
		#detect_icon.show()
		anim.play("detect")
		cat_state = CatState.DETECT
		await get_tree().create_timer(2.0).timeout
		detect_icon.hide()
	
	if player.position.distance_to(position) < CAT_RUN_DIST and cat_state == CatState.DETECT:
		cat_state = CatState.RUN
		anim.play("run")

func _on_anim_finished(anim_name: String):
	if anim_name == "run":
		set_cat_run()

func set_cat_run():
	cat_run = true
	hide()
	await get_tree().create_timer(2.0).timeout
	cat_event_component.cat_failed()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not cat_run and cat_state == CatState.RUN:
		anim.play("RESET")
		GameEvents.emit_stage_clear()
		cat_state = CatState.CATCH
		pcam.set_priority(0)
		#현재 파트너가 마이가 아니면 시작 지점으로 돌아간다
		cat_event_component.not_matching_partner_return_base(Constants.NPC_GYARU)
