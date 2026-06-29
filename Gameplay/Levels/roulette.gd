extends Node2D

signal slot_stop(_current_count: int)

@onready var button: Sprite2D = $Button
@onready var slot: Sprite2D = $EmptySlot/Slot
@onready var timer: Timer = $Timer
@onready var button_area: Area2D = $ButtonArea

@export var slot_texture: Array[CompressedTexture2D]
@export var slot_speed: float = 0.3

var texture_count : int
var current_count : int = 0
var tween : Tween
var bg_tween : Tween
var is_pressed := false


func _ready() -> void:
	timer.timeout.connect(change_image)
	texture_count = slot_texture.size()

func change_image():
	if is_pressed:
		roullet_stop()
		return
		
	current_count = wrapi(current_count +1, 0, texture_count)
	
	tween = create_tween()
	tween.tween_property(slot, "position:y", 50, slot_speed/2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(func():
		slot.texture = slot_texture[current_count]
	)
	tween.tween_property(slot, "position:y", 0, slot_speed/1.5).from(-60)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await tween.finished

	timer.start(slot_speed)

func roullet_stop():
	timer.timeout.disconnect(change_image)
	button_area.monitoring = false


func _on_button_area_body_entered(body: Node2D) -> void:
	if body is Player:
		button_pressed()

func button_pressed():
	if is_pressed:
		return
	SoundManager.play_sfx(UiSoundStreamPlayer.ROULETTE_ON) # 바닥 버튼 「카チッ」
	bg_tween = create_tween()
	bg_tween.tween_property(self, "modulate", Color(1,1,1,1), 1.0).from(Color(2,2,2,1))
	button.frame = 1
	is_pressed = true
	slot_stop.emit(current_count)
