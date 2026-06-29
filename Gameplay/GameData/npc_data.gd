class_name NpcData

const UNLOCK_LEVEL_BASE_H := 1
## 게임 플레이 방식 변경으로 사용 안함
#const UNLOCK_LEVEL_STACK_TICKET := 2

##읽지 않은 대화가 있으면 말풍선 아이콘에 new가 뜨게 하기 위한 대화 리스트 
static var npc_info: Dictionary = {
	Constants.NPC_OL : {
		"talk_event" : {
			"t_this" : {"need_love": 0, "plus_love_exp": 30},
			"t_drink" : {"need_love": 1, "plus_love_exp": 60},
			"t_change" : {"need_love": 2, "plus_love_exp": 90},
			"t_masterb" : {"need_love": 4, "plus_love_exp": 120},
			"t_onsen" : {"need_love": 5, "plus_love_exp": 120, "unlock_quest": Constants.QUESTLINE_KANKANNAVI_GET},
			"t_cook" : {"need_love": 6, "plus_love_exp": 120, "unlock_quest": Constants.QUESTLINE_KANKANNAVI_GET},
		}
			},
	Constants.NPC_GYARU : {
		"talk_event" : {
			"t_mai" : {"need_love": 0, "plus_love_exp": 30},
			"t_mai_rest" : {"need_love": 1, "plus_love_exp": 60},
			"t_mai_camera" : {"need_love": 2, "plus_love_exp": 90},
			"t_mai_cat" : {"need_love": 5, "plus_love_exp": 120, "unlock_quest": Constants.QUESTLINE_KANKANNAVI_GET},
			"t_mai_roullete" : {"need_love": 6, "plus_love_exp": 120, "unlock_quest": Constants.QUESTLINE_KANKANNAVI_GET},
		}
			}
}
static var _shared_npc_exp := {
	0: 100, # 10판 (10분)
	1: 170, # 17판 (17분) - 유지
	2: 230, # 23판 (23분) - 기존 260에서 3판 감소
	3: 300, # 30판 (30분) - 기존 325에서 2.5판 감소
	4: 380, # 38판 (38분) - 기존 455에서 7.5판 대폭 감소 (지루함 방지)
	
	# --- 장비(+10) 착용 가정 구간 (판당 20xp) ---
	# 장비를 꼈으므로 숫자가 커져도 실제 시간은 줄어듦
	5: 500, # 25판 (25분) - 장비 효과로 Lv4보다 오히려 빨리 업함 (보상 심리)
	6: 600, # 30판 (30분)
	7: 700, # 35판 (35분)
	8: 850, # 42판 (42분)
	9: 1000 # 50판 (50분) - 마지막은 달성감 있게
}

#region NPC_MAX_EXP
static var npc_max_exp : Dictionary = {
	Constants.NPC_OL : _shared_npc_exp,
	Constants.NPC_GYARU : _shared_npc_exp,
	Constants.NPC_KONIAL : {
		0 : 150,
		1 : 190,
		2 : 230,
		3 : 300,
		4 : 500,
		5 : 600,
		6 : 700,
		7 : 800,
		8 : 900,
		9 : 1000
	},
	Constants.NPC_PAZUZU : {
		0 : 100,
		1 : 150,
		2 : 200,
		3 : 300,
		4 : 500,
		5 : 600,
		6 : 700,
		7 : 800,
		8 : 900,
		9 : 1000
	},
	Constants.NPC_BUTLER : {
		0 : 130,
		1 : 290,
		2 : 400,
		3 : 400,
		4 : 500,
		5 : 600,
		6 : 700,
		7 : 800,
		8 : 900,
		9 : 1000
	}
}
#endregion

static func get_npc_max_exp(npc_type: int, love_level: int)-> int:
	return npc_max_exp[npc_type][love_level]

var animation_info = {
	Constants.NPC_KONIAL : {
		"bind" : false
	}
}

##읽지 않은 대화 있는지 체크
func new_read_event(npc: Npc) -> bool:
	if npc.npc_name not in npc_info:
		return false
		
	var talk_event = npc_info[npc.npc_name]["talk_event"]
	if talk_event.is_empty():
		return false
	
	for i in talk_event:
		
		var unlock_quest_pass: bool = true
		if talk_event[i].has("unlock_quest"):
			if not MetaProgression.has_read_event(talk_event[i]["unlock_quest"]):
				unlock_quest_pass = false
		
		if talk_event[i]["need_love"] <= npc.love_level:
			if not MetaProgression.has_read_event(i) and unlock_quest_pass:
				return true
	return false

##플레이어를 바라볼 수 없는 상태인지 확인, NpcData에 등록 안돼있으면 참을 반환
func can_player_look(npc_type: int, anim_name: String)-> bool:
	if anim_name == "" or not animation_info.has(npc_type):
		return true

	if animation_info[npc_type].has(anim_name):
		return animation_info[npc_type][anim_name]
	else :
		return true
