extends Control

const VOICE_ROOT  := "res://sound/voice/"
const DIALOG_ROOT := "res://Gameplay/Dialog/"
const SECTION_SCENE = preload("res://Gameplay/qa/voice_qa_section.tscn")

@onready var close_button: Button              = %Close
@onready var sections_container: VBoxContainer = %SectionsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var key_input: LineEdit               = %KeyInput
@onready var collapse_all_button: Button       = %CollapseAllButton
@onready var section_option: OptionButton      = %SectionOptionButton
@onready var loading_label: Label              = %LoadingLabel
@onready var loading_bar: ProgressBar          = %LoadingBar
@onready var right_panel: VBoxContainer        = %RightPanel
@onready var char_filter_option: OptionButton  = %CharFilterOption

var _current_button: Button   = null
var _all_buttons: Array       = []
var _sections: Array          = []
var _all_collapsed: bool      = false
var _thread: Thread           = null
var _progress: float          = 0.0
var _loading: bool            = false
var _char_volumes: Dictionary = {}
var _sections_data: Array     = []
var _char_filter: String      = ""

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	loading_label.show()
	loading_bar.show()
	loading_bar.value = 0.0
	scroll_container.hide()

	_loading = true
	_thread = Thread.new()
	_thread.start(_parse_data)

func _process(_delta: float) -> void:
	if _loading:
		loading_bar.value = _progress * 100.0

## 스레드에서 실행 — Node 생성 없이 순수 데이터만 수집
func _parse_data() -> void:
	var timeline_data: Dictionary = {}
	var regex := RegEx.new()
	regex.compile(r"^(.*?)#id:([a-f0-9]+)")

	var dtl_paths := _collect_dtl_paths()
	var total := float(dtl_paths.size())
	for i in dtl_paths.size():
		var dtl_path: String = dtl_paths[i]
		var base := dtl_path.get_file().get_basename()
		var file := FileAccess.open(dtl_path, FileAccess.READ)
		if not file:
			continue
		var seen: Dictionary = {}
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.begins_with("#"):
				continue
			var m := regex.search(line)
			if not m:
				continue
			var id  := m.get_string(2)
			var txt := m.get_string(1).strip_edges()
			if id in seen:
				continue
			seen[id] = true
			if not timeline_data.has(base):
				timeline_data[base] = []
			var char_name := ""
			var dialogue  := txt
			var sep := txt.find(": ")
			if sep > 0:
				var maybe := txt.substr(0, sep)
				if not " " in maybe:
					char_name = maybe
					dialogue  = txt.substr(sep + 2)
			timeline_data[base].append({id = id, char_name = char_name, text = dialogue})
		_progress = (i + 1) / total * 0.8  # dtl 파싱: 0~80%

	_progress = 0.9

	var basenames := timeline_data.keys()
	basenames.sort()
	var sections_data: Array = []
	for base in basenames:
		var items: Array = []
		for entry in timeline_data[base]:
			var path: String = VOICE_ROOT + base + "/" + entry.id + ".ogg"
			items.append({
				id        = entry.id,
				char_name = entry.char_name,
				text      = entry.text,
				path      = path,
				has_file  = ResourceLoader.exists(path)
			})
		sections_data.append({base = base, items = items})

	_progress = 1.0  # 완료
	call_deferred("_build_ui", sections_data)

## 메인 스레드에서 실행 — 섹션 헤더만 생성 (버튼은 펼칠 때 지연 로딩)
func _build_ui(sections_data: Array) -> void:
	_thread.wait_to_finish()

	for section_data in sections_data:
		var section: Node = SECTION_SCENE.instantiate()
		sections_container.add_child(section)
		section.setup(section_data.base, section_data.items, self)
		_sections.append(section)
		section_option.add_item(section_data.base, _sections.size() - 1)

	_sections_data = sections_data
	_loading = false
	loading_label.hide()
	loading_bar.hide()
	scroll_container.show()
	_build_char_filter(sections_data)
	_build_char_sliders(sections_data)

## 캐릭터별 볼륨 슬라이더를 RightPanel 하단에 생성한다.
func _build_char_sliders(sections_data: Array) -> void:
	var chars: Array[String] = []
	for sd in sections_data:
		for item in sd.items:
			if not item.char_name.is_empty() and item.char_name not in chars:
				chars.append(item.char_name)
	chars.sort()

	var sep := HSeparator.new()
	right_panel.add_child(sep)
	var label := Label.new()
	label.text = "Character Volume (dB)"
	right_panel.add_child(label)

	for ch in chars:
		_char_volumes[ch] = 0.0
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		right_panel.add_child(row)

		var name_label := Label.new()
		name_label.text = ch
		name_label.custom_minimum_size = Vector2(48, 0)
		name_label.add_theme_font_size_override("font_size", 10)
		row.add_child(name_label)

		var slider := HSlider.new()
		slider.min_value = -20.0
		slider.max_value = 20.0
		slider.value = 0.0
		slider.step = 0.5
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(0, 16)
		row.add_child(slider)

		var db_label := Label.new()
		db_label.text = "0"
		db_label.custom_minimum_size = Vector2(28, 0)
		db_label.add_theme_font_size_override("font_size", 10)
		row.add_child(db_label)

		slider.value_changed.connect(func(val: float) -> void:
			_char_volumes[ch] = val
			db_label.text = "%+.0f" % val
		)

## 섹션이 처음 펼쳐질 때 호출 — 해당 섹션 버튼을 전체 순서에 삽입
func on_section_loaded(section: Node) -> void:
	var idx := _sections.find(section)
	if idx < 0:
		return
	var insert_pos := 0
	for i in idx:
		insert_pos += _sections[i].voice_buttons.size()
	for i in section.voice_buttons.size():
		_all_buttons.insert(insert_pos + i, section.voice_buttons[i])

func _collect_dtl_paths() -> Array[String]:
	var paths: Array[String] = []
	_walk_dtl(DIALOG_ROOT, paths)
	return paths

func _walk_dtl(path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := path + entry
		if dir.current_is_dir():
			_walk_dtl(full + "/", out)
		elif entry.ends_with(".dtl"):
			out.append(full)
		entry = dir.get_next()

func _on_key_jump(key: String) -> void:
	_jump_to_key(key.strip_edges().to_lower())

func _on_jump_pressed() -> void:
	_jump_to_key(key_input.text.strip_edges().to_lower())

func _jump_to_key(key: String) -> void:
	if key.is_empty():
		return
	for section in _sections:
		var btn: Button = section.find_button_by_id(key)
		if btn:
			scroll_container.ensure_control_visible(btn)
			return

func _build_char_filter(sections_data: Array) -> void:
	char_filter_option.clear()
	char_filter_option.add_item("All")
	var chars: Array[String] = []
	for sd in sections_data:
		for item in sd.items:
			if not item.char_name.is_empty() and item.char_name not in chars:
				chars.append(item.char_name)
	chars.sort()
	for ch in chars:
		char_filter_option.add_item(ch)


func _on_char_filter_changed(idx: int) -> void:
	_char_filter = "" if idx == 0 else char_filter_option.get_item_text(idx)
	for section in _sections:
		section.set_char_filter(_char_filter)


func _log_voice_issues() -> void:
	var no_voice: Array = []
	var no_char: Array  = []
	for sd in _sections_data:
		for item in sd.items:
			if item.char_name != "" and not item.has_file:
				no_voice.append("[%s] %s: %s" % [sd.base, item.id, item.text])
			elif item.char_name == "" and item.has_file:
				no_char.append("[%s] %s: %s" % [sd.base, item.id, item.text])
	print("=== Has character / No voice: %d cases ===" % no_voice.size())
	for s in no_voice:
		print(s)
	print("=== No character / Has voice: %d cases ===" % no_char.size())
	for s in no_char:
		print(s)
	print("=== Log complete ===")


func _toggle_all() -> void:
	_all_collapsed = not _all_collapsed
	for section in _sections:
		section.set_collapsed(_all_collapsed)
	collapse_all_button.text = "Expand All" if _all_collapsed else "Collapse All"

func _on_section_selected(idx: int) -> void:
	if idx >= 0 and idx < _sections.size():
		scroll_container.ensure_control_visible(_sections[idx])

func on_button_played(btn: Button) -> void:
	if _current_button and _current_button != btn:
		_current_button.stop()
	_current_button = btn
	btn.audio_player.volume_db = _char_volumes.get(btn.char_name, 0.0)
	scroll_container.ensure_control_visible(btn)

func on_voice_finished(btn: Button) -> void:
	var idx := _all_buttons.find(btn)
	while idx >= 0 and idx < _all_buttons.size() - 1:
		idx += 1
		var next: Button = _all_buttons[idx]
		if next.has_file:
			next.play_voice()
			return
	_current_button = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
