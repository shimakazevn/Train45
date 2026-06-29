extends CanvasLayer
class_name CreditCanvas

@onready var credit_screen_anim: AnimationPlayer = $CreditScreenAnim

var is_playing:= false

func credit_screen_play(player_loop: int):
	var anim_name: String = ""
	match player_loop:
		0:anim_name = "credit1"
		1:anim_name = "credit2"
		2:anim_name = "credit3"

	if anim_name == "":
		push_warning("anim_name없음")
		return

	anim_playing(anim_name)

func anim_playing(anim_name: String):
	GameEvents.game_state_change(Constants.STATE_DONT_MOVE)
	show()
	credit_screen_anim.play(anim_name)
	is_playing = true
	
	await credit_screen_anim.animation_finished
	GameEvents.game_state_change(Constants.STATE_NORMAL)
	is_playing = false
	hide()

func final_ending_play():
	GameEvents.game_state_change(Constants.STATE_DONT_MOVE)
	show()
	credit_screen_anim.play("ending_screen")
	is_playing = true
	await credit_screen_anim.animation_finished
	Dialogic.start("epilogue_0", "ending_exit")
