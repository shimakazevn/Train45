@tool
extends DialogicEvent
class_name DialogicEmotionEvent

#-------------------------------------------------------------------------------
# DialogicEmotionEvent.gd
# 캐릭터의 표정을 변경하는 커스텀 Dialogic 이벤트입니다.
#-------------------------------------------------------------------------------

var character: DialogicCharacter = null             # 대상 캐릭터 리소스
var portrait_override: String = ""               # 기본 포트레이트 대신 사용할 키
var emotion_identifier: String = ""             # 적용할 감정 키 (Face 자식 노드 이름)

var _character_identifier: String = ""           # 내부 식별자 저장 변수
# 에디터용 프로퍼티: 값 변경 시 ui_update_needed.emit()로 UI 갱신
var character_identifier: String:
	get:
		return _character_identifier
	set(value):
		_character_identifier = value
		character = DialogicResourceUtil.get_character_resource(value)
		portrait_override = ""
		ui_update_needed.emit()

# 정규식: emotion 이벤트 스크립트 파싱 (type, name, portrait, expression)
# 그룹1=type, 그룹2=name, 그룹3=portrait(optional), 그룹4=expression
#var regex := RegEx.create_from_string(r'^(emotion)\s*([^\(\s]+)(?:\(([^)]+)\))?\s+(\S+)$')
var regex := RegEx.new()
#-------------------------------------------------------------------------------
# 초기화
#-------------------------------------------------------------------------------
func _init() -> void:
	event_name = "Emotion"
	event_category = "Main"
	regex = RegEx.new()

#-------------------------------------------------------------------------------
# 실행: 선택된 감정을 Portrait 시스템에 전달
#-------------------------------------------------------------------------------
func _execute() -> void:
	if character and emotion_identifier != "":
		var extra_data := "set Face/%s" % emotion_identifier
		dialogic.Portraits.change_character_extradata(character, extra_data)
	finish()

#region 저장/로딩
func get_shortcode_parameters() -> Dictionary:
	return {
		"character": {"property": "character_identifier", "default": ""},
		"portrait":   {"property": "portrait_override",   "default": ""},
		"emotion":    {"property": "emotion_identifier", "default": ""},
	}

func to_text() -> String:
	if character_identifier != "" and emotion_identifier != "":
		if portrait_override != "":
			return "emotion %s(%s) %s" % [character_identifier, portrait_override, emotion_identifier]
		else:
			return "emotion %s %s" % [character_identifier, emotion_identifier]
	return "emotion"

func from_text(text: String) -> void:
	var parts := text.strip_edges().split(" ")
	if parts.size() >= 2:
		var raw_char := parts[1]
		var re := RegEx.new()
		re.compile("^(.+)\\((.+)\\)$")
		var m := re.search(raw_char)
		if m:
			character_identifier = m.get_string(1)  # ✅ setter 호출
			portrait_override     = m.get_string(2)
		else:
			character_identifier = raw_char         # ✅ setter 호출
			portrait_override     = ""
		if parts.size() >= 3:
			emotion_identifier = parts[2]
#endregion

#region 에디터 UI
func build_event_editor() -> void:
	add_header_edit('character_identifier', ValueType.DYNAMIC_OPTIONS, {
		'placeholder': 'Character',
		'file_extension': '.dch',
		'mode': 2,
		'suggestions_func': get_character_suggestions,
		'icon': load("res://addons/dialogic/Editor/Images/Resources/character.svg"),
		'autofocus': true
	})

	add_header_edit('portrait_override', ValueType.DYNAMIC_OPTIONS, {
		'placeholder': 'Portrait',
		'collapse_when_empty': true,
		'suggestions_func': get_portrait_suggestions,
		'icon': load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	}, "character_identifier != ''")

	add_header_edit('emotion_identifier', ValueType.DYNAMIC_OPTIONS, {
		'placeholder': 'Select Emotion',
		'suggestions_func': get_emotion_suggestions,
		'icon': load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	})

func is_valid_event(string:String) -> bool:
	return string.begins_with("emotion")
#endregion

#region 헬퍼
func get_character_suggestions(search_text: String) -> Dictionary:
	return DialogicUtil.get_character_suggestions(search_text, character, false, false, editor_node)

func get_portrait_suggestions(search_text: String) -> Dictionary:
	return DialogicUtil.get_portrait_suggestions(search_text, character, true, "Default portrait")

func get_emotion_suggestions(search_text: String) -> Dictionary:
	var suggestions := {}
	if character_identifier != "":
		character = DialogicResourceUtil.get_character_resource(character_identifier)
	if not character:
		return suggestions

	var portrait_key := portrait_override if portrait_override != "" else character.default_portrait
	if not character.portraits.has(portrait_key):
		portrait_key = character.default_portrait

	var info: Dictionary = character.portraits[portrait_key]
	if not info.has("scene") or info["scene"] == null:
		return suggestions

	var scene: PackedScene = load(info["scene"])
	if not scene:
		return suggestions

	var inst: Node = scene.instantiate()
	var face := inst.get_node_or_null("Face")
	if face:
		for child in face.get_children():
			if child is Node:
				var name := child.name
				if search_text == "" or name.to_lower().find(search_text.to_lower()) != -1:
					suggestions[name] = {'value': name, 'text': name}
	inst.queue_free()
	return suggestions
#endregion

######################## 코드 완성 & 하이라이팅 ########################
func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, _word:String, symbol:String) -> void:
	# 'emotion ' 입력 후 공백: 캐릭터 제안
	if symbol == ' ' and line.begins_with('emotion'):
		var check_re := RegEx.new()
		check_re.compile(r"^emotion\s+[^\s()]+(?:\([^\)]*\))?$")  # 캐릭터까지만, 혹은 (포트레이트)까지
		var match := check_re.search(line)
		if match:
			# portrait가 아직 안 닫혔다면 캐릭터 제안만 허용
			if not line.ends_with(')'):
				CodeCompletionHelper.suggest_characters(TextNode, CodeEdit.KIND_MEMBER)

	var regex = RegEx.new()
	regex.compile(r"^emotion\s+([^\s()]+)(?:\(([^\)]+)\))?(?:\s+([^\s]+))?$")
	var result := regex.search(line)

	# '(' 입력 시: 포트레이트 제안
	if symbol == '(' and result and result.get_string(1) != "":
		CodeCompletionHelper.suggest_portraits(TextNode, result.get_string(1))

	# 포트레이트 뒤 공백에서 감정(emotion) 제안
	if symbol == ' ' and result and result.get_string(1) != "":
		var char_id := result.get_string(1)
		var portrait := result.get_string(2)

		# 감정 제안을 위한 캐릭터 및 포트레이트 설정
		var ch := DialogicResourceUtil.get_character_resource(char_id)
		if ch:
			var portrait_key := portrait if portrait != "" else ch.default_portrait
			if not ch.portraits.has(portrait_key):
				portrait_key = ch.default_portrait
			var info: Dictionary = ch.portraits[portrait_key]
			if info.has("scene") and info["scene"] != null:
				var scene: PackedScene = load(info["scene"])
				if scene:
					var inst: Node = scene.instantiate()
					var face := inst.get_node_or_null("Face")
					if face:
						for child in face.get_children():
							if child is Node:
								var name := child.name
								TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, name, name + ' ', TextNode.syntax_highlighter.normal_color)
					inst.queue_free()


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	# 에디터 진입 시 'emotion' 키워드 제안
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'emotion', 'emotion ', event_color, null)

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	var word := line.get_slice(' ', 0)
	dict[line.find(word)] = {"color": event_color}
	dict[line.find(word) + word.length()] = {"color": Highlighter.normal_color}

	var rx := RegEx.new()
	rx.compile(r"\(([^)]+)\)")
	var m := rx.search(line)
	if m:
		dict[m.get_start(1) - 1] = {"color": event_color.lerp(Highlighter.normal_color, 0.6)}
		dict[m.get_end(1) + 1] = {"color": Highlighter.normal_color}

	return dict
