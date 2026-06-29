class_name ChapterInfo


##goal 변경시 csv번역파일도 필수 변경!
var chapters : Dictionary = {
	0: {
		"title": "CHAPTER_TITLE_0",
		"description": "",
		"goal": 0
	},
	1: {
		"title": "CHAPTER_TITLE_1",
		"description": "CHAPTER_DESCRIPTION_1",
		"goal": 5 #id:143a 에서 5번까지라고 했기때문에
	},
	2: {
		"title": "CHAPTER_TITLE_2",
		"description": "CHAPTER_DESCRIPTION_2",
		"goal": 7
	},
	3: {
		"title": "CHAPTER_TITLE_3",
		"description": "CHAPTER_DESCRIPTION_3",
		"goal": 8
	},
	4: {
		"title": "CHAPTER_TITLE_4",
		"description": "CHAPTER_DESCRIPTION_4",
		"goal": 9
	},
	5: {
		"title": "CHAPTER_TITLE_5",
		"description": "CHAPTER_DESCRIPTION_5",
		"goal": 10
	},
	6: {
		"title": "CHAPTER_TITLE_6",
		"description": "CHAPTER_DESCRIPTION_6",
		"goal": 10
	}
}

func get_chapter_data(chapter_num: int) -> Dictionary:
	if chapters.has(chapter_num):
		return chapters[chapter_num]
	return {}

func get_chapter_title(chapter_num: int) -> String:
	if chapters.has(chapter_num):
		return chapters[chapter_num]["title"]
	else:
		return ""

func get_chapter_description(chapter_num: int)-> String:
	if chapters.has(chapter_num):
		return chapters[chapter_num]["description"]
	else:
		return ""

func get_chapter_goal(chapter_num: int) -> int:
	if chapters.has(chapter_num):
		return chapters[chapter_num]["goal"]
	else:
		return 0

func get_current_chapter_data() -> Dictionary:
	return get_chapter_data(MetaProgression.get_current_chapter())
