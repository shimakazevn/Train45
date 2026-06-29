extends Sprite2D

@export var stage : Level
var player : Player
var player_velocity : Vector2
@onready var animation_player = $AnimationPlayer

func _ready():
	player = stage.player as Player
	
	

func _process(_delta):
	if player == null :
		return
	if player.velocity_component.velocity == null:
		return
	player_velocity = player.velocity_component.velocity
	
	if player_velocity.is_equal_approx(Vector2.ZERO):
		animation_player.play("idle")
	else:
		animation_player.play("RESET")
		animation_player.stop()
