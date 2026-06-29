extends AnimationPlayer

@export var player: Player
@onready var area_2d: Area2D = $Area2D
@export var pazuzu: CharacterBody2D

func _ready() -> void:
	self.animation_finished.connect(_anim_finished)
	GameEvents.stage_change.connect(_on_stage_change)
	if MetaProgression.get_current_chapter() >= 4:
		pazuzu.queue_free()
	area_2d.monitoring = false

func _on_stage_change():
	area_2d.monitoring = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		self.play("drop")
		call_deferred("set_unmonitaring")

func set_unmonitaring():
	area_2d.monitoring = false

func _anim_finished(anim_name: String):
	if anim_name == "drop":
		pazuzu.queue_free()
