extends Control
class_name FlashLightComponent

@export var player: Player

@onready var flash_light_right: TextureRect = $FlashLightRight
@onready var flash_light_left: TextureRect = $FlashLightLeft
@onready var collision_right: CollisionShape2D = $FlashArea/CollisionRight
@onready var collision_left: CollisionShape2D = $FlashArea/CollisionLeft

enum FlashDir {LEFT, RIGHT}
var current_dir: FlashDir
var light_on: bool = false
var light_tween: Tween

func _ready() -> void:
	flash_light_right.hide()
	flash_light_left.hide()
	set_dir(FlashDir.RIGHT)

func _process(_delta: float) -> void:
	if player.move_dir.x > 0:
		set_dir(FlashDir.RIGHT)
	elif player.move_dir.x < 0:
		set_dir(FlashDir.LEFT)
		

func set_dir(dir: FlashDir):
	if current_dir == dir: # 현재 방향이 변경 방향과 같다면 리턴
		return
	
	# 방향 전환시 잠시 꺼짐
	if light_on: # 켜져 있던 경우에만 소등음 (최초 진입 시 불필요한 재생 방지)
		SoundManager.play_sfx(UiSoundStreamPlayer.SWITCH_OFF)
	light_on = false
	collision_right.disabled = true
	collision_left.disabled = true
	
	current_dir = dir
	if dir == FlashDir.RIGHT:
		flash_light_right.show()
		flash_light_left.hide()
	elif dir == FlashDir.LEFT:
		flash_light_right.hide()
		flash_light_left.show()
	
	if light_tween:
		light_tween.kill()
	light_tween = create_tween()
	light_tween.tween_property(self, "modulate:a", 1.0, 0.25).from(0.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_ELASTIC)
	light_tween.tween_callback(set_light_on)

func set_light_on():
	light_on = true
	SoundManager.play_sfx(UiSoundStreamPlayer.SWITCH_ON)
	if current_dir == FlashDir.RIGHT:
		collision_right.disabled = false
		collision_left.disabled = true
	elif current_dir == FlashDir.LEFT:
		collision_right.disabled = true
		collision_left.disabled = false


func _on_flash_area_area_entered(area: Area2D) -> void:
	if area.get_parent() is AnomalyEvil:
		var evil: AnomalyEvil = area.get_parent()
		evil.is_hitting = true

func _on_flash_area_area_exited(area: Area2D) -> void:
	if area.get_parent() is AnomalyEvil:
		var evil: AnomalyEvil = area.get_parent()
		evil.is_hitting = false
