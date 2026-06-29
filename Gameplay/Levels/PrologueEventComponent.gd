extends EventComponent

@export var player : Player
@export var ol : Npc
@export var gyaru : Npc

@export var block_area : Area2D
@export var talk1_area : Area2D
@export var find_tuto_area : Area2D
@export var tuto_anomaly : Area2D

@export var konial_cam : PhantomCamera2D

var talk_reina := false
var talk_mai := false
var anomaly_area_in := false

# talk_reina/talk_mai가 모두 참이 되기 전까지 TUTO1 알림을 주기적으로 재발신하는 타이머
var tuto1_timer : Timer

signal talk_complete

func _ready():
	GameEvents.quest_process.connect(_on_quest_process)
	dialog_start("prologue")
	tuto_anomaly.hide()
	tuto1_timer = Timer.new()
	tuto1_timer.wait_time = 15.0
	tuto1_timer.timeout.connect(_on_tuto1_timer_timeout)
	add_child(tuto1_timer)
	# 대화 중에는 타이머를 일시정지(남은 시간 보존), 대화가 끝나면 재개
	Dialogic.timeline_started.connect(func(): tuto1_timer.paused = true)
	Dialogic.timeline_ended.connect(func(): tuto1_timer.paused = false)

func _on_quest_process(quest_str: String):
	match quest_str:
		"prologue_reina":
			talk_reina = true
		"prologue_mai":
			talk_mai = true
		"prologue_dialog_end":
			NotionEvent.notion("NOTI_PROLOGUE_TUTO1")
			tuto1_timer.start()
		"konial_look":
			konial_cam.set_priority(100)
		"prologue_find_ready":
			konial_cam.set_priority(0)
			talk1_area.monitoring = false
			NotionEvent.notion("NOTI_PROLOGUE_TUTO2", Constants.SD_ICONS[Constants.NPC_KONIAL])
			find_tuto_area.monitoring = true
			ol.queue_free()
			gyaru.queue_free()
		"prologue_find_start":
			find_tuto_area.monitoring = false
			tuto_anomaly.show()
			tuto_anomaly.monitoring = true
			player.player_tuto_action.connect(_on_find_tuto_action)

	# Check for quest completion
	if talk_reina and talk_mai:
		talk_complete.emit()
		block_area.monitoring = false
		tuto1_timer.stop()


func _on_tuto1_timer_timeout():
	NotionEvent.notion("NOTI_PROLOGUE_TUTO1")


func _on_block_area_body_entered(_body: Node2D):
	dialog_start("prologue_system")

func _on_talk_1_area_body_entered(_body: Node2D) -> void:
	dialog_start("prologue_stage2")

func _on_find_tuto_start_area_body_entered(_body: Node2D) -> void:
	dialog_start("prologue_stage3")

func _on_find_tuto_action():
	if anomaly_area_in:
		dialog_start("prologue_stage4")
	else:
		NotionEvent.notion("NOTI_PROLOGUE_FAILED", Constants.SD_ICONS[Constants.NPC_KONIAL])


func _on_tuto_anomaly_area_entered(_area: Area2D) -> void:
	anomaly_area_in = true
func _on_tuto_anomaly_area_exited(_area: Area2D) -> void:
	anomaly_area_in = false
