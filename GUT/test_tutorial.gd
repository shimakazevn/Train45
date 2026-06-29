# test_tuto_manager.gd
extends GutTest

const NPC_TYPE := 0
var manager : TutoManager

func before_each():
	manager = TutoManager.new()
	
	var npc = Npc.new()
	npc.love_level = 0
	
	var partner_array: Array = []
	partner_array.resize(NPC_TYPE + 1)
	partner_array[NPC_TYPE] = npc
	
	var partner_manager = PartnerManager.new()
	partner_manager.partner = partner_array
	
	var tutorial_page = TutorialPage.new()
	tutorial_page.partner_manager = partner_manager
	
	manager.tutorial_page = tutorial_page

func test_get_call_dialog_timeline():
	var dialog:String = manager.get_call_dialog_timeline("inven")
	
	assert_eq(dialog, manager.TUTO_INVEN, "출력 잘못됨")
