extends Node2D

@export var evil_play_ground: EvilPlayGround

@export var bg_evil: PackedScene
@onready var spwan_position_right: Sprite2D = $SpwanPositionRight
@onready var spwan_position_left: Sprite2D = $SpwanPositionLeft
@onready var timer: Timer = $Timer

var current_bg_evil_count:= 0

func _ready() -> void:
	evil_play_ground.play_starting.connect(_on_play_started)
	spwan_position_right.hide()
	spwan_position_left.hide()

func _on_play_started():
	timer.start()
	timer.timeout.connect(_on_spwan_timeout)

func _on_spwan_timeout():
	if current_bg_evil_count > evil_play_ground.evil_count:
		return
	timer.wait_time = randf_range(0.05, 0.3)
	bg_evil_spwan()

func bg_evil_spwan():
	var bg_evil_instance = bg_evil.instantiate()
	var spawn_dir := randi()%2
	var rand_offset := Vector2(0.0, randf_range(-47.0, 47.0))
	if spawn_dir == 0 :
		bg_evil_instance.position = spwan_position_right.position + rand_offset
		bg_evil_instance.current_dir = AnomalyEvil.EvilDir.R
	else:
		bg_evil_instance.position = spwan_position_left.position + rand_offset
		bg_evil_instance.current_dir = AnomalyEvil.EvilDir.L
	self.add_child(bg_evil_instance)
	bg_evil_instance.tree_exited.connect(_on_evil_dead)
	current_bg_evil_count += 1

func _on_evil_dead():
	current_bg_evil_count -= 1
