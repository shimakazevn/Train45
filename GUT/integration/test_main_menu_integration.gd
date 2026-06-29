extends GutTest

const IntegrationHelpers = preload("res://GUT/integration/integration_helpers.gd")
const MAIN_MENU := preload("res://Gameplay/main_menu.tscn")


func before_each() -> void:
	IntegrationHelpers.clear_integration_save_slot()
	IntegrationHelpers.reset_game_events_for_title()


func after_each() -> void:
	IntegrationHelpers.clear_integration_save_slot()
	IntegrationHelpers.reset_game_events_for_title()


func test_load_button_visibility_matches_save_presence_on_disk() -> void:
	IntegrationHelpers.seed_nonempty_save()
	var menu = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	await wait_frames(3, "main_menu _ready")
	assert_eq(menu.load_button.visible, MetaProgression.has_anyone_save_data(), "Load 버튼은 디스크 세이브 유무와 일치해야 함")


func test_load_button_hidden_when_integration_slot_empty_and_no_other_saves() -> void:
	if MetaProgression.has_anyone_save_data():
		pending("다른 슬롯에 세이브가 있어 Load 표시를 단정할 수 없음 — user:// 세이브를 비운 뒤 재실행")
		return
	var menu = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	await wait_frames(3, "main_menu _ready")
	assert_false(menu.load_button.visible, "세이브가 없으면 Load 숨김")


func test_recollect_visibility_matches_unlock_flag() -> void:
	IntegrationHelpers.seed_ending_cleared_save()
	var menu = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	await wait_frames(3, "main_menu _ready")
	var expect_unlock: bool = MetaProgression.is_unlock_recollect()
	assert_eq(menu.recollect_button.visible, expect_unlock, "회상 버튼은 is_unlock_recollect와 일치")
	assert_eq(menu.train_ending.visible, expect_unlock, "엔딩 배경은 해금 시 표시")


func test_option_menu_opens_and_closes_without_change_scene() -> void:
	# 씬에 title_labels가 비어 있으므로 _ready 전에 TitleLabel* 노드로 채운 뒤 Main과 동일하게 연결한다.
	var menu = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	await wait_frames(3, "main_menu _ready")
	var opt_inst: Node = menu.option_menu.instantiate()
	_fill_options_title_labels_from_scene(opt_inst)
	opt_inst.tree_exited.connect(menu.on_option_exit)
	menu.add_child(opt_inst)
	await wait_frames(2, "options instantiate")
	var opt_menu: Control = opt_inst as Control
	var ap := opt_menu.get_node_or_null("CanvasLayer/Panel/AnimationPlayer") as AnimationPlayer
	assert_not_null(ap, "옵션 AnimationPlayer 경로 확인")
	var canvas_layer: Node = opt_menu.get_node_or_null("CanvasLayer")
	var exited: Array = [false]
	var mark := func() -> void: exited[0] = true
	opt_menu.tree_exited.connect(mark)
	if canvas_layer:
		canvas_layer.tree_exited.connect(mark)
	# is_playing()이면 뒤로가기가 무시되므로, 재생 종료 또는 짧은 유예 후에만 _on_back_pressed 호출.
	var open_msec := Time.get_ticks_msec()
	var saw_playing: Array = [false]
	var idle_pred := func() -> bool:
		if ap.is_playing():
			saw_playing[0] = true
			return false
		if saw_playing[0]:
			return true
		return Time.get_ticks_msec() - open_msec >= 500
	var idle: bool = await wait_until(idle_pred, 5.0, "options safe idle before back")
	assert_true(idle, "옵션 AnimationPlayer가 닫기에 안전한 유휴 상태가 되어야 함")
	opt_menu._on_back_pressed()
	var ok: bool = await wait_until(func() -> bool: return exited[0], 10.0, "options tree_exited")
	assert_true(ok, "옵션 퇴장 후 루트 또는 CanvasLayer가 트리에서 빠져야 함")


func test_load_menu_opens_and_closes_without_change_scene() -> void:
	IntegrationHelpers.seed_nonempty_save()
	var menu = MAIN_MENU.instantiate()
	add_child_autofree(menu)
	await wait_frames(3, "main_menu _ready")
	menu._on_load_pressed()
	await wait_frames(2, "load menu instantiate")
	var load_root := _find_child_with_script(menu, "res://Gameplay/load_menu.gd")
	assert_not_null(load_root, "로드 메뉴가 자식으로 추가되어야 함")
	var exited: Array = [false]
	load_root.tree_exited.connect(func() -> void: exited[0] = true)
	load_root._on_back_pressed()
	var ok: bool = await wait_until(func() -> bool: return exited[0], 5.0, "load menu tree_exited")
	assert_true(ok, "로드 메뉴 퇴장 후 제거되어야 함")


func _find_child_with_script(root: Node, script_path: String) -> Node:
	for c in root.get_children():
		var s: Script = c.get_script() as Script
		if s and s.resource_path == script_path:
			return c
	return null


func _fill_options_title_labels_from_scene(opt_root: Node) -> void:
	var p := "CanvasLayer/Panel/"
	var labels: Array[Label] = [
		opt_root.get_node(p + "TitleLabelKR") as Label,
		opt_root.get_node(p + "TitleLabelJP") as Label,
		opt_root.get_node(p + "TitleLabelZH") as Label,
		opt_root.get_node(p + "TitleLabelCN") as Label,
		opt_root.get_node(p + "TitleLabelEN") as Label,
	]
	opt_root.set("title_labels", labels)
