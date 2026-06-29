extends Node
class_name NpcAnomaly

@export var anomaly_name: String
@export var anomaly_anim_name: String

@export var anomaly: Area2D
@export var current_npc: Node2D

func _ready() -> void:
	get_parent().stage_start.connect(_on_stage_start)
	call_deferred("set_npc_anomaly")
	
func _on_stage_start():
	pass

func set_npc_anomaly():
	var npc = current_npc.get_child(0) as Npc
	if is_instance_valid(npc):
		npc.anim_change(anomaly_anim_name)
		var collision = anomaly.get_child(0) as CollisionShape2D
		collision.position = npc.position
		
		_set_y_offset(collision)

func _set_y_offset(col: CollisionShape2D):
	match anomaly_name:
		"chibi":
			col.position.y -= 30.0
		_:
			col.position.y -= 160.0 # npc offset
