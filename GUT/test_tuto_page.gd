extends GutTest

var tuto_page: TutorialPanel

## TutorialPanel은 id가 [member TutoManager.tuto_data]에 있어야 하고, 이 테스트의 단계별 버튼 기대값은 페이지가 정확히 3장일 때 맞는다.
func _test_tutos_three_pages() -> Tutos:
	var t := Tutos.new()
	t.id = TutoManager.TEST_TUTO
	for i in 3:
		var p := TutoPage.new()
		p.description = "test page %d" % i
		t.tuto_pages.append(p)
	return t


func before_each() -> void:
	tuto_page = preload("res://Gameplay/GameData/Tutorials/tuto_page.tscn").instantiate()
	tuto_page.tuto_manager = TutoManager.new()
	tuto_page.tuto_manager.init_res_path()
	tuto_page.tuto_manager.tuto_data[TutoManager.TEST_TUTO] = _test_tutos_three_pages()
	add_child(tuto_page)


func after_each() -> void:
	tuto_page.free()


func test_open_tuto() -> void:
	tuto_page.open_tuto(TutoManager.TEST_TUTO)
	assert_not_null(tuto_page.current_tuto, "튜토 리소스 감지안됨")
	assert_eq(tuto_page.arrow_next.visible, true, "포커스 틀림")
	assert_eq(tuto_page.arrow_prev.visible, false, "포커스 틀림")
	assert_eq(tuto_page.confirm_button.visible, false, "포커스 틀림")
	tuto_page._on_arrow_next_pressed()
	assert_eq(tuto_page.arrow_next.visible, true, "포커스 틀림")
	assert_eq(tuto_page.arrow_prev.visible, true, "포커스 틀림")
	assert_eq(tuto_page.confirm_button.visible, false, "포커스 틀림")
	tuto_page._on_arrow_next_pressed()
	assert_eq(tuto_page.arrow_next.visible, false, "포커스 틀림")
	assert_eq(tuto_page.arrow_prev.visible, true, "포커스 틀림")
	assert_eq(tuto_page.confirm_button.visible, true, "포커스 틀림")


## 여러 튜토를 연속으로 열면 활성 튜토가 두 번째 것으로 교체되고 페이지가 초기화되어야 한다.
func test_open_tuto_multiple() -> void:
	tuto_page.open_tuto(TutoManager.TEST_TUTO)
	assert_eq(tuto_page.current_tuto.id, TutoManager.TEST_TUTO, "첫 튜토가 활성화되어야 한다")

	tuto_page.open_tuto(TutoManager.TUTO_BASE_H_EVENT)
	assert_eq(tuto_page.current_tuto.id, TutoManager.TUTO_BASE_H_EVENT, "두 번째 튜토로 전환되어야 한다")
	assert_eq(tuto_page.current_page, 0, "튜토 전환 시 첫 페이지로 초기화되어야 한다")


## 재오픈 회귀: 페이지를 넘긴 뒤 같은 튜토를 다시 열면 1페이지로 돌아와야 한다.
## Bug(리포트 #20): 처음 표시되는 튜토리얼이 1페이지가 아니라 2페이지로 표시되던 버그.
## Fix: open_tuto()가 current_page를 0으로 초기화 후 update_ui 호출.
func test_reopen_resets_to_first_page() -> void:
	tuto_page.open_tuto(TutoManager.TEST_TUTO)
	tuto_page._on_arrow_next_pressed()   # 2페이지로 이동
	assert_eq(tuto_page.arrow_prev.visible, true, "2페이지에서는 이전 화살표가 보여야 한다")

	tuto_page.open_tuto(TutoManager.TEST_TUTO)   # 같은 튜토 재오픈
	assert_eq(tuto_page.current_page, 0, "재오픈 시 current_page가 0으로 초기화되어야 한다 (#20)")
	assert_eq(tuto_page.arrow_prev.visible, false,
		"재오픈 시 1페이지로 돌아와 이전 화살표가 숨겨져야 한다 (#20)")
