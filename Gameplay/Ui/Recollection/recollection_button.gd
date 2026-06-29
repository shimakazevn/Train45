extends Button
class_name RecollectionButton

signal h_scene_play(npc_type: int)

var h_res_info: HSceneRes
@onready var h_scene_title_label: Label = %HSceneTitleLabel
@onready var lock_screen: ColorRect = %LockScreen
@onready var event_texture: TextureRect = %EventTexture

var is_locked:= true

func _ready() -> void:
	lock_screen.hide()
	if h_res_info:
		h_scene_title_label.text = h_res_info.scene_description
		if h_res_info.preview_texture:
			event_texture.texture = h_res_info.preview_texture
		else:
			event_texture.texture = null
	
	if is_locked:
		lock_screen.show()
	
	hide_mouse_on_button()
	set_multiplier()
	ready_override()

func ready_override():
	pass

#region 오버라이드
## 오버라이드 함수
func hide_mouse_on_button():
	pass

func set_multiplier():
	pass

func get_ticket_multiplier()-> int:
	return 0
#endregion

func _on_pressed() -> void:
	if is_locked or TransitionScreen.get_is_transition():
		return
	
	#print("button")
	GameEvents.emit_on_npc_h_event(h_res_info.partner, h_res_info.scene_name, get_ticket_multiplier())
	h_scene_play.emit(h_res_info.partner)
