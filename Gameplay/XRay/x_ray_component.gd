extends Node2D

@export var free_action_component: HSceneFreeActionComponent
var containers: Array[Node2D]

var current_npc: int
var current_anim: AnimationPlayer
var current_xray_container: Node2D

var current_xray_scene: Array[XRayScene]
var current_xray_anim: AnimationPlayer # 사정전 애님
var current_xray_after_anim: AnimationPlayer # 사정후 애님
var active_xray_anim: AnimationPlayer # 현재 적용된 애님

func _ready() -> void:
	free_action_component.anim_info_changed.connect(_on_anim_info_changed)
	free_action_component.free_action_end.connect(_on_free_action_end)
	free_action_component.cumming.connect(_on_cumming)
	
	containers.resize(Constants.NpcTypes.size()-1)
	containers[Constants.NpcTypes.REINA] = $XRayReinaContainer
	containers[Constants.NpcTypes.MAI] = $XRayMaiContainer
	containers[Constants.NpcTypes.KONIAL] = $XRayKonialContainer
	containers[Constants.NpcTypes.BUTLER] = $XRayButlerContainer
	containers[Constants.NpcTypes.PAZUZU] = $XRayPazuzuContainer

func _on_anim_info_changed(next_npc:int, next_anim:AnimationPlayer, scene_name: String):
	current_xray_scene.clear()
	
	#print(scene_name)
	current_npc = next_npc
	current_anim = next_anim
	current_anim.stop()
	
	
	
	for i in containers.size():
		if i == next_npc:
			current_xray_container = containers[i]
			containers[i].show()
		else:
			containers[i].hide()
	
	for i in current_xray_container.get_children():
		var xray = i as XRayScene
		var anim = i.get_child(0) as AnimationPlayer
		
		###애니메이션 재생되면 자동으로 show되기 때문에 stop하고 hide한다
		anim.stop()
		xray.hide()
		
		if anim.has_animation(scene_name): # 해당하는 이름의 씬이 있을때
			current_xray_scene.append(xray)
			if xray.is_type == XRayScene.XrayTypes.NORMAL:
				current_xray_anim = anim
				active_xray_anim = current_xray_anim
			elif xray.is_type == XRayScene.XrayTypes.AFTER_CUM:
				current_xray_after_anim = anim
		else:
			i.hide()
		###애니메이션 재생되면 자동으로 show되기 때문에 stop하고 hide한다
		#current_xray_anim.stop()
		#current_xray_after_anim.stop()
		#xray.hide()

func _process(_delta: float) -> void:
	
	if current_anim and active_xray_anim:
		
		#if active_xray_anim:
			#print(active_xray_anim.current_animation)
		#else:
			#print("none")
		if current_anim.is_playing():
			var current_anim_name = current_anim.current_animation
			var pos = current_anim.current_animation_position
			var speed = current_anim.speed_scale


			# B가 이미 같은 애니메이션을 재생 중이 아니라면 시작
			var active_current_anim: String = active_xray_anim.current_animation
			if active_current_anim != current_anim_name and active_xray_anim.has_animation(current_anim_name):
				active_xray_anim.play(current_anim_name)
			
			if active_xray_anim.has_animation(current_anim_name):
				# 위치와 속도 동기화
				active_xray_anim.seek(pos, true)
				active_xray_anim.speed_scale = speed
		else:
			# A가 멈췄다면 B도 멈춤
			#active_xray_anim.stop()
			pass

## 사정시 사정 애님으로 변경함
func _on_cumming():
	active_xray_anim = current_xray_after_anim

func _on_free_action_end():
	current_anim = null
	current_xray_container = null
	current_xray_scene.clear()
	current_xray_anim = null
	current_xray_after_anim = null
	active_xray_anim = null
