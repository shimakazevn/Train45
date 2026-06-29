class_name NpcTimelineData

# 각 챕터별 종착점까지 도착했을 시 분기(해당 조건들은 변경될 수 있음. 내용과 다른 경우 갱신 필요)
# 챕터 1 : 파트너 둘의 호감도를 각각 1이상 올려야 함
# 챕터 2 : 티켓을 일정 이상 모아야 함 
# 챕터 3 : 8번째 칸 도달시 무조건 파주주 스테이지로 가기 때문에 발생하지 않음, 파주주를 능욕하고 가둔 뒤 다음 챕터 이동
# 챕터 4 : 칸칸네비를 만들기 위한 챕터, 종착점을 지정하지 않으면 이곳으로 도달함, 집사의 창고 도착후 다음 챕터 이동
# 챕터 5 : 코니알이 집사를 인간으로 변신시키고 호감도를 올리는 챕터, 파주주가 갇힌 스테이지로 이동시 다음 챕터 이동
# 챕터 6 : 풀려난 파주주가 코니알을 구속함, *이곳부터 코니알이 아닌 파주주가 대신 등장*

##분기별 타임라인입니다
static func get_talk_type(npc: Npc, stage_type: int, current_chapter: int, is_anomaly_find: bool, is_prologue: bool = false, extra_info:= "", quest_failed:= false) -> Dictionary:
	#시작 지점일 때
	if stage_type == Constants.TYPE_BASE:
		if is_prologue:
			return {"timeline":"prologue_stage", "label":""}
		else:
			return {"timeline":"basetalk", "label":""}
	
	#종착점일 때
	if stage_type == Constants.TYPE_COMPLETE:
		#파트너(레이나,마이)
		if npc.npc_name == Constants.NPC_OL or npc.npc_name == Constants.NPC_GYARU:
			if current_chapter == 3:
				return {"timeline":"chapter3_ch_talk", "label":""}
			if extra_info == "engine_room":
				return {"timeline":"chapter6_npc_talk", "label":""}
			if extra_info == "d_cat":
				return {"timeline":"stage_complete_partner", "label":"d_cat"}
			if extra_info == "d_stuckdoor":
				return {"timeline":"stage_complete_partner", "label":"d_stuckdoor"}
			return {"timeline":"stage_complete_partner", "label":""}
		#코니알
		elif npc.npc_name == Constants.NPC_KONIAL:
			if quest_failed:
				return {"timeline":"stage_complete", "label":"quest_failed"}
			else:
				return {"timeline":"stage_complete", "label":""}
		#파주주
		elif npc.npc_name == Constants.NPC_PAZUZU:
			if extra_info == "engine_room":
				return {"timeline":"chapter6_npc_talk", "label":""}
			return {"timeline":"stage_complete_pazuzu", "label":""}

	#탐색중일 때
	elif stage_type == Constants.TYPE_STAGE or stage_type == Constants.TYPE_SAFE:
		#파트너(레이나,마이)
		if npc.npc_name == Constants.NPC_OL or npc.npc_name == Constants.NPC_GYARU:
			if is_anomaly_find:#이변 찾아냄
				return {"timeline":"stage_clear_talk", "label":""}
			else:#이변 찾는중
				return {"timeline":"stage_talk", "label":""}
	
	return {"timeline":"", "label":""}
