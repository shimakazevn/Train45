extends Node2D
class_name HugGhostRoom

@export var hug_ghost: HugGhost
@export var hug_ghosts_seats: Array[Sprite2D]
@export var player: Player
@export var room_light: ColorRect

@onready var hug_ghost_timer: Timer = $HugGhostTimer
@onready var player_detect_area: Area2D = $PlayerDetectArea
@onready var charm: HugGhostCharm = $Charm

var near_player_seats: Array[Area2D]

const GHOST_SHOW_DELAY := [6.0, 2.0, 4.0, 6.0] # 귀신의 라이프 = 3부터 시작


func _ready() -> void:
	hug_ghost.ghost_kill.connect(off_room_light)
	charm.hide()
	hug_ghost_timer.timeout.connect(_on_ghost_timer_timeout)
	hug_ghost_timer.start()
	hug_ghost_timer.wait_time = GHOST_SHOW_DELAY[hug_ghost.is_life]
	set_charm()
	
	for i in hug_ghosts_seats:
		i.hide()

func _on_ghost_timer_timeout():
	if not hug_ghost:
		return
		
	hug_ghost_timer.wait_time = GHOST_SHOW_DELAY[hug_ghost.is_life]
	hug_ghost_timer.start()
	
	near_player_seats = player_detect_area.get_overlapping_areas()
	if near_player_seats.is_empty():
		return
	
	var candidates: Array = []
	for area in near_player_seats:
		var pos: Vector2 = area.owner.position
		if pos != hug_ghost.before_pos:
			candidates.append(pos)

	# 전부 같은 위치라면 → 이동 안 함 (또는 그대로 사용)
	if candidates.is_empty():
		return
		# 또는:
		# hug_ghost.set_hug_ghost(hug_ghost.before_pos)

	var next_pos: Vector2 = candidates.pick_random()
	hug_ghost.set_hug_ghost(next_pos)

func _process(_delta: float) -> void:
	if player:
		player_detect_area.position = player.position

func set_charm():
	if hug_ghosts_seats.size() > 0:
		charm.set_charm_state(HugGhostCharm.CharmState.IN, hug_ghosts_seats.pick_random().position)

func off_room_light():
	var light_tween := get_tree().create_tween()
	light_tween.tween_property(room_light, "self_modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
