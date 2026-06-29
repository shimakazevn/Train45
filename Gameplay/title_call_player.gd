extends AudioStreamPlayer

@export var voice_elniko: Array[AudioStream]
@export var voice_mangoparty: Array[AudioStream]

func call_elniko():
	_play_random(voice_elniko)

func call_mangoparty():
	_play_random(voice_mangoparty)

func _play_random(voices: Array[AudioStream]) -> void:
	if voices.is_empty():
		return
	stream = voices[randi() % voices.size()]
	play()
