## 에디터 도구: 아이템 박스 수집 컴포넌트.
## 지정된 디렉터리에서 아이템 박스를 포함하는 씬을 재귀 검색하고,
## 결과를 JSON 파일로 저장한다. 에디터 인스펙터에서 버튼을 눌러 실행한다.
@tool
extends Node

## 에디터 인스펙터 버튼. 클릭 시 [method collect_item_box]를 실행한다.
@export_tool_button("Collect Item Box") var collect_item_box_button = collect_item_box
## 검색할 대상 씬 파일명.
@export var target_scene_name: String = "item_box.tscn"
## 재귀 검색 시작 디렉터리 경로.
@export var search_root: String = "res://Gameplay/Levels/"
## 수집된 아이템 박스 씬 경로 배열.
@export var boxes: Array[String] = []

## 수집 결과를 저장할 JSON 파일 경로.
const JSON_PATH := "res://Gameplay/GameData/item_box_scenes.json"

## [member search_root]에서 [member target_scene_name]을 포함하는 씬을 재귀 검색하고
## [member boxes]에 저장한 뒤 JSON으로 내보낸다.
func collect_item_box():
	print("\n🔍 Searching for:", target_scene_name)
	var new_boxes: Array[String] = []
	_search_folder(search_root, new_boxes)
	set("boxes", new_boxes)

	print("✅ Search complete. Found %d boxes.\n" % new_boxes.size())
	for b in new_boxes:
		print(" - ", b)
	
	save_boxes_to_json()


## [member boxes] 배열의 씬들을 로드하여 아이템 박스 데이터를 추출하고
## [member JSON_PATH]에 JSON으로 저장한다.
func save_boxes_to_json():
	if boxes.is_empty():
		push_warning("⚠ boxes is empty. Collect first.")
		return

	var dict_result: Dictionary = {}

	for path in boxes:
		var scene := ResourceLoader.load(path)
		if scene == null:
			push_warning("⚠ Failed to load: %s" % path)
			continue

		var inst: Level = scene.instantiate()
		var box_data := _find_item_box_data(inst)
		dict_result[path] = box_data
		inst.queue_free()

	# ✅ 정식 JSON 저장 프로세스 사용
	var file := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	if file == null:
		push_error("❌ Failed to open file: %s" % JSON_PATH)
		return

	var json_text := JSON.stringify(dict_result, "\t")
	file.store_string(json_text)
	file.flush()  # 🔥 버퍼 즉시 디스크 반영
	file.close()

	print("💾 JSON successfully written to:", JSON_PATH)


## [param root] 노드 하위에서 [RewardItemBox]를 재귀적으로 찾아 데이터를 수집한다.
## 힌트·아이템·루트코인·티켓 등의 이름을 추출하여 배열로 반환한다.
func _find_item_box_data(root: Node) -> Array:
	var results: Array = []
	
	#print(results)
	for child in root.get_children():
		if child is RewardItemBox:
			var base_name: String

			if child.hint:
				base_name = child.hint.id
			elif child.item:
				base_name = child.item.id
			elif child.route_coin > 0:
				base_name = "route_coin" + str(child.route_coin)
			elif child.ticket > 0:
				base_name = "ticket" + str(child.ticket)
			else:
				base_name = ""  # 혹은 빈 문자열 ""

			var data := { "name": base_name }
			results.append(data)
		
		# 재귀적으로 모든 하위 노드 검사
		results += _find_item_box_data(child)

	return results


## [param path] 디렉터리를 재귀 탐색하여 [member target_scene_name]을 포함하는
## [code].tscn[/code] 파일 경로를 [param result]에 추가한다.
func _search_folder(path: String, result: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	for file_name in dir.get_files():
		if not file_name.ends_with(".tscn"):
			continue

		var file_path := path.path_join(file_name)
		var text := FileAccess.get_file_as_string(file_path)

		if text.find(target_scene_name) != -1:
			result.append(file_path)

	for subdir in dir.get_directories():
		_search_folder(path.path_join(subdir), result)
