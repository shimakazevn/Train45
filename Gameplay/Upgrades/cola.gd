extends Sprite2D

@export var choice_circle : PackedScene

@onready var anim: AnimationPlayer = $AnimationPlayer
var player: Player
var anomaly_collision: CollisionShape2D
@onready var white_rect: ColorRect = $WhiteRect
@onready var bome_anim: AnimationPlayer = $WhiteRect/AnimationPlayer

const ICON_COLA = preload("res://resources/ui/icons/icons20.png")

const SHAKE_INCREASE_VALUE := 6.0 # 걸어다닐때마다 흔들리는 양

var shake_percent := 0.0
var min_speed_scale: float = 0.2
var max_speed_scale: float = 5.0
const SHAKE_START_PERCENT := 10.0
var is_shaking := false

var cola_fired := false

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)

	position = Vector2(-15, -140)
	(player.animation_player as AnimationPlayer).current_animation_changed.connect(_on_player_anim_changed)

func _process(_delta: float) -> void:
	if is_shaking:
		shake_percent = clampf(shake_percent + (SHAKE_INCREASE_VALUE*_delta), 0.0, 100.0)
		#print(shake_percent)
		set_vibe()
		if shake_percent >= 100.0:
			cola_fire()

func _on_player_anim_changed(anim_name: String):
	if anim_name == "walk":
		is_shaking = true
		anim.play("shake")
	else:
		is_shaking = false
		anim.stop()
		
func set_vibe():
	if shake_percent < SHAKE_START_PERCENT:
		bome_anim.stop()
	else:
		if not bome_anim.is_playing():
			bome_anim.play("bome")
	if cola_fired:
		bome_anim.stop()
	
	var normalized_shake = (shake_percent - SHAKE_START_PERCENT) / (100.0 - SHAKE_START_PERCENT)
	var speed_scale = lerp(min_speed_scale, max_speed_scale, clampf(normalized_shake, 0.0, 1.0))
	
	bome_anim.speed_scale = speed_scale

func cola_fire():
	if cola_fired:
		return

	var choice_circle_instance = choice_circle.instantiate()
	if anomaly_collision:
		choice_circle_instance.target_position = anomaly_collision.global_position
		choice_circle_instance.position = self.global_position
		var floor_manager = get_tree().get_first_node_in_group("floormanager") as FloorManager
		floor_manager.current_level.add_child(choice_circle_instance)
	else:
		NotionEvent.notion("NOTI_ITEM_COLA1", ICON_COLA)
		NotionEvent.notion("NOTI_ITEM_COLA2", ICON_COLA)

	cola_fired = true

func _on_stage_clear():
	cola_fired = true
