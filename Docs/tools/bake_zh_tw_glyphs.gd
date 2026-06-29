# [KR] 번체(zh_TW) 셰이핑용 글리프를 NotoSansCJKtc 임포트 preload에 추가하는 도구.
#
# [KR] 배경: 에디터의 "번역에서 글리프 미리 등록"은 번역 리소스의 locale("zh")로
# [KR] 셰이핑해 간체(ZHS) 변형 GID를 굽지만, 런타임은 zh_TW(ZHT)로 셰이핑하므로
# [KR] (LanguageManager의 로케일 리맵 참고) 번체 글리프 ~960개가 캐시 미스되어
# [KR] 번체에서 로딩이 느려진다. 이 스크립트가 zh_TW용 GID를 수집해 별도 preload
# [KR] 항목("zh_TW 글리프")으로 추가한다.
#
# [KR] 사용법 (에디터에서 글리프를 다시 구웠다면 재실행):
# [KR]   godot --headless --path <프로젝트> -s res://Docs/tools/bake_zh_tw_glyphs.gd
# [KR]   이후 godot --headless --import --path <프로젝트> 로 재임포트
extends SceneTree

const IMPORT_PATH := "res://resources/font/NotoSansCJKtc-Regular.otf.import"
const FONT_PATH := "res://resources/font/NotoSansCJKtc-Regular.otf"
const ENTRY_NAME := "zh_TW 글리프"
const CSV_PATHS := [
	"res://Gameplay/Dialog/Translation/dialogic_timeline_translations.csv",
	"res://Gameplay/Dialog/Translation/dialogic_character_translations.csv",
	"res://Gameplay/Dialog/Translation/Ui/UI_Text_Translations.csv",
]

func _initialize():
	# 1) 모든 CSV의 zh 열 텍스트 수집
	var texts: Array[String] = []
	for csv_path in CSV_PATHS:
		var f := FileAccess.open(csv_path, FileAccess.READ)
		if f == null:
			push_error("CSV 열기 실패: " + csv_path)
			continue
		var header := f.get_csv_line()
		var zh_col := header.find("zh")
		if zh_col == -1:
			push_error("zh 열 없음: " + csv_path)
			continue
		while not f.eof_reached():
			var row := f.get_csv_line()
			if row.size() > zh_col and not row[zh_col].is_empty():
				texts.append(row[zh_col])
	print("zh string count: ", texts.size())

	# 2) zh_TW로 셰이핑해 GID 수집
	var tc: FontFile = load(FONT_PATH)
	var ts := TextServerManager.get_primary_interface()
	var gids := {}
	for text in texts:
		var tl := TextLine.new()
		tl.add_string(text, tc, 16, "zh_TW")
		for g in ts.shaped_text_get_glyphs(tl.get_rid()):
			gids[g["index"]] = true
	var gid_list := gids.keys()
	gid_list.sort()
	print("zh_TW shaped GID count: ", gid_list.size())

	# 3) .import의 preload 배열에 항목 추가/갱신 (기존 항목은 그대로 둠)
	var imp := FileAccess.open(IMPORT_PATH, FileAccess.READ).get_as_text()
	var entry := "{\n\"chars\": [],\n\"glyphs\": [%s],\n\"name\": \"%s\",\n\"size\": Vector2i(16, 0),\n&\"variation_embolden\": 0.0\n}" % [
		", ".join(gid_list.map(func(g): return str(g))), ENTRY_NAME]

	if imp.contains("\"name\": \"%s\"" % ENTRY_NAME):
		# [KR] 기존 zh_TW 항목 교체
		var s := imp.find("{", imp.find("\"name\": \"%s\"" % ENTRY_NAME) - 4096)
		# [KR] 항목 시작 위치를 못 찾는 엣지 케이스 방지를 위해 정규식으로 교체
		var regex := RegEx.new()
		regex.compile("\\{[^{}]*\"name\": \"%s\"[^{}]*\\}" % ENTRY_NAME)
		imp = regex.sub(imp, entry)
	else:
		var tail := imp.rfind("}]")
		if tail == -1:
			push_error("preload 배열 끝(}])을 찾지 못함")
			quit(1)
			return
		imp = imp.substr(0, tail + 1) + ", " + entry + imp.substr(tail + 1)

	var out := FileAccess.open(IMPORT_PATH, FileAccess.WRITE)
	out.store_string(imp)
	out.close()
	print("preload entry written: ", ENTRY_NAME)
	quit()
