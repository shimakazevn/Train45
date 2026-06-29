extends Sprite2D
class_name HugGhost

signal ghost_kill

@export var play_wall: CollisionShape2D
@export var ghost_timer: Timer

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

# 抱きつき 동작별 효과음
const SFX_MISS := preload("res://sound/sfx/missed_the_attack.mp3")      # ① 포옹을 풀었을 때
const SFX_GRAB_OFUDA := preload("res://sound/sfx/grab_the_ofuda.mp3")   # ② 부적에 껴안았을 때
const SFX_GRAB_BODY := preload("res://sound/sfx/grab_the_body.mp3")     # ③ 플레이어를 껴안았을 때

var game_over:= false
const MAX_LIFE := 3
var is_life: int = MAX_LIFE
const anim_speed := [1.0, 1.0, 0.9, 0.8]

var before_pos: Vector2

# 런 지속 게이지(run_stage_gauge 그룹). 귀신 라이프를 비율로 표시한다.
var run_gauge: Node

func _ready() -> void:
	self.hide()
	anim.animation_finished.connect(_on_anim_finished)
	GameEvents.stage_clear.connect(_on_stage_clear)
	# 게이지 노드가 그룹에 등록된 뒤 참조하도록 지연 호출
	_init_run_gauge.call_deferred()

func _init_run_gauge() -> void:
	run_gauge = get_tree().get_first_node_in_group("run_stage_gauge")
	if run_gauge:
		run_gauge.show_and_fill()

func set_hug_ghost(pos: Vector2):
	if game_over:
		return
	position = pos
	anim.speed_scale = anim_speed[is_life]
	anim.play("hug")
	before_pos = pos

func attack():
	var charms: Array[Area2D] = area_2d.get_overlapping_areas()
	var target_player: Array[Node2D] = area_2d.get_overlapping_bodies()
	#print(charms, target_player)
	
	if charms:
		_play_sfx(SFX_GRAB_OFUDA)
		ghost_timer.paused = true
		anim.speed_scale = 1.0
		anim.play("hit")
		var charm: HugGhostCharm = charms[0].get_parent()
		charm.set_charm_state(HugGhostCharm.CharmState.OUT)
		is_life -= 1
		if run_gauge:
			run_gauge.set_ratio(float(is_life) / MAX_LIFE)
	elif target_player:
		_play_sfx(SFX_GRAB_BODY)
		var player: Player = target_player[0]
		player.rape("hug_ghost")
		game_over = true
	else:
		_play_sfx(SFX_MISS)

func _play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()

func _on_anim_finished(anim_name: String):
	if anim_name == "hit":
		ghost_timer.paused = false
		if is_life == 0:
			if run_gauge:
				run_gauge.hide()
			self.queue_free()
			play_wall.disabled = true
			ghost_kill.emit()

func _on_stage_clear():
	if run_gauge:
		run_gauge.hide()
	self.queue_free()
	play_wall.disabled = true
	ghost_kill.emit()
