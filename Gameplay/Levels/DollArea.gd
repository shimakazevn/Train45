class_name Doll extends Area2D

@onready var animation_player = $AnimationPlayer
@export var ghost : CharacterBody2D

func _ready():
	ghost.die_anim_finished.connect(_on_die)
	
	
func _on_die():
	animation_player.play("die")
