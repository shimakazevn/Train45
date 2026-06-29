class_name HSceneData

const H_SCENE_DATA_PATH := "res://Gameplay/GameData/HSceneData/"

## 캐릭터 스프라이트의 오프셋만큼 보정한다
static var npc_sprite_offset: Dictionary ={
	Constants.NPC_OL: Vector2(0, -122),
	Constants.NPC_GYARU: Vector2(0, -128),
	Constants.NPC_KONIAL: Vector2(0, -116),
	Constants.NPC_PAZUZU: Vector2(0, -97),
	Constants.NPC_BUTLER: Vector2(0, -122)
}

var h_scenes : Dictionary = {
	Constants.NPC_OL : [
		"res://resources/HScene/h_scene_ol.tscn",
		"res://resources/HScene/h_scene_ol_ver2.tscn"
		],
	Constants.NPC_GYARU : [
		"res://resources/HScene/h_scene_gyaru.tscn",
		"res://resources/HScene/h_scene_gyaru_ver2.tscn"
		],
	Constants.NPC_KONIAL : [
		"res://resources/HScene/h_scene_konial.tscn"
		],
	Constants.NPC_PAZUZU : [
		"res://resources/HScene/h_scene_pazuzu.tscn"
		],
	Constants.NPC_BUTLER : [
		"res://resources/HScene/h_scene_butler.tscn"
		]
}

var h_full_scene : Dictionary = {
	Constants.NPC_OL : {
		101 : "res://resources/FullScene/full_anim_ol.tscn",
		102 : "res://resources/FullScene/full_anim_reina_2.tscn"
	},
	Constants.NPC_GYARU : {
		101 : "res://resources/FullScene/full_anim_gal.tscn",
		102 : "res://resources/FullScene/full_anim_gal_stuckdoor.tscn",
		103 : "res://resources/FullScene/full_anim_mai_2.tscn"
	},
	Constants.NPC_KONIAL : {
		101 : "res://resources/FullScene/full_anim_konial.tscn",
		102 : "res://resources/FullScene/full_anim_konial_2.tscn"
	}
}

func get_h_scene(npc_type: int, event_num: int) -> HScene:
	var path : String
	#한 스프라이트당 최대 19개의 씬이 들어가므로 해당 넘버링의 스프라이트를 반환한다.
	if event_num > 0 and event_num < 20:
		path = h_scenes[npc_type][0]
	if event_num > 20 and event_num < 40:
		path = h_scenes[npc_type][1]

	var h_scene_packed = ResourceLoader.load(path) as PackedScene
	var h_scene_instance = h_scene_packed.instantiate()
	return h_scene_instance 

func get_full_scene(npc_type: int, event_num: int) -> NpcFullScene:
	var full_scene_path = get_h_full_scene_path(npc_type, event_num)
	var anim_full_packed = ResourceLoader.load(full_scene_path) as PackedScene
	var full_sprite_instance = anim_full_packed.instantiate()
	return full_sprite_instance

func get_h_full_scene_path(npc_type: int, scene_num: int) -> String:
	return h_full_scene[npc_type][scene_num]


##h리소스와 현재 엔피씨, h씬 번호를 받아 위치값을 리턴한다
static func get_h_scene_position(h_res_array: Array, npc_type: int, scene_num: int)-> Vector2:
	for i in h_res_array:
		if i.partner == npc_type:
			if i.scene_name == "scene"+str(scene_num):
				if scene_num >= 100: #씬이 full H씬일 경우 위치를 변경하지 않는다
					return Vector2.ZERO
				else:
					return i.is_position - npc_sprite_offset[npc_type]
	
	push_error("해당하는 엔피씨 타입: %d의 scene%d가 없습니다."%[npc_type, scene_num])
	return Vector2.ZERO
	
