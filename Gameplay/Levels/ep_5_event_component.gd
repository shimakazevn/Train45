extends EventComponent

@export var pazuzu_cam: PhantomCamera2D
@export var pazuzu: Npc
@export var light_rect: PackedScene
@export var player_copies : Node2D
@export var train : Sprite2D
@export var train_destroyed: CompressedTexture2D
@onready var stage_light: DirectionalLight2D = %DirectionalLight2D
@onready var player_position: Marker2D = $"../PlayerPosition"
@onready var pazuzu_cam_position: Marker2D = $"../PazuzuCamPosition"

var tween: Tween
var light_instance : ColorRect

const PAZUZU_CAM_POSITION_1 := Vector2(549,219) # 주인공 일행과 만나는 장면
const PAZUZU_CAM_POSITION_2 := Vector2(853,219) # 코니알과 대면하는 장면
const PAZUZU_CAM_POSITION_3 := Vector2(970,235) # 코니알이 역으로 당하는 장면

func _ready():
	stage_light.show()
	GameEvents.quest_process.connect(_on_quest_process)
	var current_level = get_parent() as Level
	current_level.stage_start.connect(_on_stage_start)
	
func _on_stage_start():
	dialog_start("chapter5_complete")
	pazuzu_cam.set_priority(100)

func _on_quest_process(quest_str: String):
	match quest_str:
		"meet_player":
			GameEvents.emit_position_change(GameEvents.NpcTypes.PLAYER, player_position.position.x, player_position.position.y)
			pazuzu_cam_position.position = PAZUZU_CAM_POSITION_1
			var _tween = get_tree().create_tween()
			_tween.tween_property(pazuzu_cam, "zoom", Vector2.ONE, 1.0)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		"screen_flash":
			screen_flash()
		"screen_flash_set":
			screen_flash_set()
		"destroyed_train":
			train.texture = train_destroyed
		"meet_konial":
			pazuzu_cam_position.position = PAZUZU_CAM_POSITION_2
			GameEvents.emit_npc_flip(GameEvents.NpcTypes.PAZUZU, true)
		"show_player_copy":
			player_copies.show()
		"konial_scene":
			pazuzu_cam_position.position = PAZUZU_CAM_POSITION_3
			player_copies.hide()


func screen_flash():
	light_instance = light_rect.instantiate()
	pazuzu.npc_sprite.add_child(light_instance)
	tween = create_tween()
	tween.tween_property(light_instance, "modulate:a", 1, 0.3)
	tween.tween_property(stage_light, "energy", 0.0, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	TransitionScreen.transition_white()
	
	
func screen_flash_set():
	tween = create_tween()
	tween.tween_property(stage_light, "energy", 2.0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(light_instance, "modulate:a", 0, 1.0)
	tween.tween_callback(light_instance.queue_free)
