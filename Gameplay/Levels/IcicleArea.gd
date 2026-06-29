extends Area2D

@export var icicle_set : Node2D

func _on_area_entered(area):
	if icicle_set.hit_monitaring == false:
		return
	var player = area.get_parent() as Player
	#player.find_faild.emit()
	player.rape("snow")
