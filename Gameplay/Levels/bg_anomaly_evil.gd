extends Sprite2D
class_name BgAnomalyEvil

@onready var anim: AnimationPlayer = $Anim

enum EvilType {YELLOW=1, PUPLE, RED}
var is_type: EvilType = EvilType.values()[randi() % EvilType.values().size()]

enum EvilDir {L = -1,R = 1}
var current_dir:= EvilDir.R

var spd := randf_range(200.0, 500.0)
var finish_pos_x : float

func _ready() -> void:
	var anim_name:String = "evil" + str(is_type)
	anim.play(anim_name)
	
	var scale_rand := randf_range(0.15, 0.55)
	scale = Vector2(scale_rand,scale_rand)
	
	if current_dir == EvilDir.L:
		self.flip_h = true
	else:
		self.flip_h = false
	
	finish_pos_x = position.x - (900.0*current_dir)

func _process(delta: float) -> void:
	position.x += -(current_dir*spd)*delta
	
	# 방향에 따라 비교 연산 다르게 처리
	if current_dir == EvilDir.R and position.x <= finish_pos_x:
		queue_free()
	elif current_dir == EvilDir.L and position.x >= finish_pos_x:
		queue_free()
