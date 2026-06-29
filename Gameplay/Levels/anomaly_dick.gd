extends Node2D

@export var player: Player
@export var anim_player: AnimationPlayer
@export var body_area: Area2D

enum State {IDLE, RUN, DETECT, DEAD}
var current_state :State = State.IDLE
var taget_move_position: Vector2 = Vector2.ZERO

const MIN_ESCAPE_DISTANCE := 200
const FORCED_ESCAPE_DISTANCE := 500
const MAP_MIN_X := 0 + 50
const MAP_MAX_X := 1920 - 50
const MOVE_SPEED := 150.0

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)

func _physics_process(delta: float) -> void:
	#스테이지 클리어시 DEAD상태이므로 바로 리턴함
	if current_state == State.DEAD:
		return
	
	if current_state == State.RUN:
		var dir := (taget_move_position - global_position).normalized()
		global_position += dir * MOVE_SPEED * delta

		# 목적지에 가까워졌으면 정지
		if global_position.distance_to(taget_move_position) < 10.0:
			current_state = State.IDLE
			anim_player.play("dick_idle")

	if is_player_anomaly_in_area():
		if player:
			if player.is_charging:
				if current_state != State.DETECT:
					current_state = State.DETECT
				if anim_player.current_animation != "dick_hit":
					anim_player.play("dick_hit")
			else:
				if current_state == State.DETECT:
					set_run_mode()

func _on_dick_detact_area_body_entered(body: Node2D) -> void:
	if body is Player and current_state != State.DEAD:
		set_run_mode()

func set_run_mode():
	var my_x := global_position.x
	var player_x := player.global_position.x
	var escape_distance := randf_range(MIN_ESCAPE_DISTANCE, MIN_ESCAPE_DISTANCE + 100)

	if my_x < player_x:
		# 왼쪽으로 도망
		taget_move_position.x = clamp(my_x - escape_distance, MAP_MIN_X, MAP_MAX_X)
		if abs(taget_move_position.x - my_x) < MIN_ESCAPE_DISTANCE:
			taget_move_position.x = clamp(my_x + FORCED_ESCAPE_DISTANCE, MAP_MIN_X, MAP_MAX_X)
	else:
		# 오른쪽으로 도망
		taget_move_position.x = clamp(my_x + escape_distance, MAP_MIN_X, MAP_MAX_X)
		if abs(taget_move_position.x - my_x) < MIN_ESCAPE_DISTANCE:
			taget_move_position.x = clamp(my_x - FORCED_ESCAPE_DISTANCE, MAP_MIN_X, MAP_MAX_X)

	taget_move_position.y = randf_range(310.0, 355.0)
	current_state = State.RUN
	anim_player.play("dick_run")

##플레이어의 find_area영역 안에 들어오면 호출
func is_player_anomaly_in_area()-> bool:
	if body_area.has_overlapping_areas():
		return true
	return false

func _on_stage_clear():
	current_state = State.DEAD
	anim_player.play("dick_dead")
