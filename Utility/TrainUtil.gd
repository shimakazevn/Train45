class_name TrainUtil

static func get_res_from_path(path: String) -> Array:
	var result: Array = []
	if DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path.path_join(file_name)
				var res = ResourceLoader.load(full_path)

				result.append(res)

			file_name = dir.get_next()
		dir.list_dir_end()
	return result

## [deprecated] preload()로 대체됨
#static func import_json_file(path: String) -> Dictionary:
#	var file := FileAccess.open(path, FileAccess.READ)
#	if file == null:
#		push_error("JSON 파일 열기 실패: %s" % path)
#		return {}
#	var content := file.get_as_text()
#	file.close()
#	var json := JSON.new()
#	var result := json.parse(content)
#	if result != OK:
#		push_error("JSON 파싱 오류 (%d): %s" % [json.get_error_line(), json.get_error_message()])
#		return {}
#	if typeof(json.data) != TYPE_DICTIONARY:
#		push_error("JSON 데이터가 Dictionary 형식이 아닙니다: %s" % path)
#		return {}
#	return json.data

static func load_undialogue_csv_as_dictionary(path: String) -> Dictionary:
	var data := {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CSV 파일을 열 수 없습니다: " + path)
		return data
	
	# 첫 줄은 헤더
	var headers := file.get_csv_line()
	var header_index := {
		"key": headers.find("key"),
		"speaker": headers.find("_Speaker"),
		"scene": headers.find("_Scene"),
		"type": headers.find("_Type"),
	}

	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() < headers.size():
			continue  # 잘린 줄은 무시

		var key := line[header_index["key"]]
		data[key] = {
			"speaker": line[header_index["speaker"]],
			"scene": line[header_index["scene"]],
			"type": line[header_index["type"]],
		}

	file.close()
	return data
