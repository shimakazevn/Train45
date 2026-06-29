extends Node2D
class_name HugGhostCharm

@export var hug_ghost_room: HugGhostRoom
@onready var anim: AnimationPlayer = $CharmSprite/AnimationPlayer

const CHARM_RESPWAN_TIME := 7.0
var before_pos: Vector2

func _ready() -> void:
	anim.animation_finished.connect(_on_anim_finished)

enum CharmState { IN,IDLE,OUT }
func set_charm_state(state: CharmState, pos: Vector2 = Vector2.ZERO):
	self.show()
	var offset_y := 32.0
	if pos != Vector2.ZERO:
		self.position = pos + Vector2(0,offset_y)
		before_pos = pos
	match state:
		CharmState.IN:
			anim.play("in")
		CharmState.OUT:
			anim.play("out")
			
			await get_tree().create_timer(CHARM_RESPWAN_TIME).timeout
			var next_pos: Vector2 = hug_ghost_room.hug_ghosts_seats.pick_random().position
			while before_pos == next_pos:
				next_pos = hug_ghost_room.hug_ghosts_seats.pick_random().position
			
			set_charm_state(CharmState.IN, hug_ghost_room.hug_ghosts_seats.pick_random().position)
		CharmState.IDLE:
			anim.play("idle")

func _on_anim_finished(anim_name: String):
	if anim_name == "in":
		anim.play("idle")
