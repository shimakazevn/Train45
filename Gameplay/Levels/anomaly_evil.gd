extends Node2D
class_name AnomalyEvil

signal catch_player
## 죽기 시작하는 순간(set_die) 발신. 큐프리(완전 소멸)가 아닌 이 시점에 런 게이지를 갱신한다.
signal died

@onready var evil_sprite_2d: Sprite2D = $EvilSprite2d
@onready var anim: AnimationPlayer = $EvilSprite2d/Anim
@onready var hit_anim: AnimationPlayer = $EvilSprite2d/HitEffect/Anim

enum EvilType {YELLOW=1, PUPLE, RED}
var is_type: EvilType = EvilType.values()[randi() % EvilType.values().size()]

var player: Player
var is_die:= false
var is_life := 55
var spd := randf_range(36.0, 100.0) # 이동속도 -10%
const lower_spd := 12.0

var is_hitting:= false

enum EvilDir {L = -1,R = 1}
var current_dir:= EvilDir.R

var tween: Tween

func _ready() -> void:
	var anim_name:String = "evil" + str(is_type)
	anim.play(anim_name)     
	if current_dir == EvilDir.L:
		evil_sprite_2d.flip_h = true
	else:
		evil_sprite_2d.flip_h = false

func _process(delta: float) -> void:
	if player and not is_die:
		var target_pos := Vector2(player.position.x, self.position.y)
		
		var current_spd: float
		if not is_hitting:
			current_spd = spd
			if hit_anim.is_playing():
				hit_anim.play("RESET")
		else:
			current_spd = lower_spd
			is_life -= 1
			if not hit_anim.is_playing():
				hit_anim.play("hit")
		
		if is_life <= 0:
			# 빛으로 처치된 순간 소멸음 재생 (스테이지 클리어 일괄 소멸은 set_die에서 직접 호출돼 제외됨)
			SoundManager.play_sfx(UiSoundStreamPlayer.FADING_SUCCUBUS)
			set_die()
		self.position = self.position.move_toward(target_pos, current_spd * delta)

func set_die():
	if is_die: # 중복 호출(빛 처치 후 스테이지 클리어 등) 시 재진입 방지
		return
	is_die = true
	died.emit()

	if hit_anim.is_playing():
		hit_anim.play("RESET")

	tween = create_tween().set_parallel()
	tween.tween_property(self, "position:x", position.x+(100 * current_dir), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(evil_sprite_2d, "self_modulate", Color.TRANSPARENT, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.chain().tween_callback(self.queue_free)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player.rape("evil"+str(is_type))
		catch_player.emit()

func _on_evil_stage_clear():
	set_die()
