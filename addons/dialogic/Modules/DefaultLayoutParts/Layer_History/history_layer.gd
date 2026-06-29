@tool
extends DialogicLayoutLayer

## Example scene for viewing the History
## Implements most of the visual options from 1.x History mode

@onready var nine_patch_rect: NinePatchRect = $NinePatchRect

@export_group('Look')
@export_subgroup('Font')
@export var font_use_global_size: bool = true
@export var font_custom_size: int = 15
@export var font_use_global_fonts: bool = true
@export_file('*.ttf', '*.tres') var font_custom_normal: String = ""
@export_file('*.ttf', '*.tres') var font_custom_bold: String = ""
@export_file('*.ttf', '*.tres') var font_custom_italics: String = ""

@export_subgroup('Buttons')
@export var show_open_button: bool = true
@export var show_close_button: bool = true

@export_group('Settings')
@export_subgroup('Events')
@export var show_all_choices: bool = true
@export var show_join_and_leave: bool = true

@export_subgroup('Behaviour')
@export var scroll_to_bottom: bool = true
@export var show_name_colors: bool = true
@export var name_delimeter: String = ": "

var scroll_to_bottom_flag: bool = false
const SCROLL_SPEED: float = 350.0

@export_group('Private')
@export var HistoryItem: PackedScene = null

var history_item_theme: Theme = null
var _show_history_button: Button

func get_show_history_button() -> Button:
	if _show_history_button:
		return _show_history_button
	return $ShowHistory


func get_hide_history_button() -> Button:
	return $HideHistory


func get_history_box() -> ScrollContainer:
	return %HistoryBox


func get_history_log() -> VBoxContainer:
	return %HistoryLog


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_show_history_button = $ShowHistory
	_show_history_button.visible = false
	DialogicUtil.autoload().History.open_requested.connect(_on_show_history_pressed)
	DialogicUtil.autoload().History.close_requested.connect(_on_hide_history_pressed)
	GameEvents.dialogic_h_event_on.connect(_on_free_action_start)
	GameEvents.h_event_end.connect(_on_free_action_end)
	await get_tree().process_frame
	var anim_parent := get_tree().get_first_node_in_group("vn_animation_parent")
	if anim_parent:
		_show_history_button.reparent(anim_parent, true)
	var text_sub: Node = DialogicUtil.autoload().get(&'Text')
	if text_sub != null and text_sub.call(&'is_textbox_visible'):
		_show_history_button.visible = true
	GameEvents.textbox_visible_changed.connect(_on_textbox_visible_changed)

func _apply_export_overrides() -> void:
	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	if history_subsystem != null:
		get_show_history_button().visible = show_open_button and history_subsystem.get(&'simple_history_enabled')
		#print(show_open_button and history_subsystem.get(&'simple_history_enabled'))
	else:
		set(&'visible', false)

	history_item_theme = Theme.new()

	if font_use_global_size:
		history_item_theme.default_font_size = get_global_setting(&'font_size', font_custom_size)
	else:
		history_item_theme.default_font_size = font_custom_size

	if font_use_global_fonts and ResourceLoader.exists(get_global_setting(&'font', '') as String):
		history_item_theme.default_font = load(get_global_setting(&'font', '') as String) as Font
	elif ResourceLoader.exists(font_custom_normal):
		history_item_theme.default_font = load(font_custom_normal)

	if ResourceLoader.exists(font_custom_bold):
		history_item_theme.set_font(&'RichtTextLabel', &'bold_font', load(font_custom_bold) as Font)
	if ResourceLoader.exists(font_custom_italics):
		history_item_theme.set_font(&'RichtTextLabel', &'italics_font', load(font_custom_italics) as Font)



func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if scroll_to_bottom_flag and get_history_box().visible and get_history_log().get_child_count():
		scroll_to_bottom_flag = false
		await get_tree().process_frame
		get_history_box().ensure_control_visible(get_history_log().get_children()[-1] as Control)
	if get_history_box().visible:
		var joy_left_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		var joy_right_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		var scroll_dir: float
		if abs(joy_left_y) > 0.2:
			scroll_dir = joy_left_y
		elif abs(joy_right_y) > 0.2:
			scroll_dir = joy_right_y
		else:
			scroll_dir = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		if scroll_dir != 0.0:
			get_history_box().scroll_vertical += int(scroll_dir * SCROLL_SPEED * delta)


func _on_show_history_pressed() -> void:
	DialogicUtil.autoload().paused = true
	# [KR] 백로그는 대화 진행만 막으면 되므로 BGM는 계속 재생
	# [EN] Backlog only needs to halt dialog progress, so keep BGM playing
	DialogicUtil.autoload().Audio.resume()
	show_history()


func show_history() -> void:
	for child: Node in get_history_log().get_children():
		child.queue_free()

	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	for info: Dictionary in history_subsystem.call(&'get_simple_history'):
		var history_item : Node = HistoryItem.instantiate()
		history_item.set(&'theme', history_item_theme)
		match info.event_type:
			"Text":
				if info.has('character') and info['character']:
					if show_name_colors:
						history_item.call(&'load_info', info['text'], info['character']+name_delimeter, info['character_color'])
					else:
						history_item.call(&'load_info', info['text'], info['character']+name_delimeter)
				else:
					history_item.call(&'load_info', info['text'])
			"Character":
				if !show_join_and_leave:
					history_item.queue_free()
					continue
				history_item.call(&'load_info', '[i]'+info['text'])
			"Choice":
				var choices_text: String = ""
				if show_all_choices:
					for i : String in info['all_choices']:
						if i.ends_with('#disabled'):
							choices_text += "-  [i]("+i.trim_suffix('#disabled')+")[/i]\n"
						elif i == info['text']:
							choices_text += "-> [b]"+i+"[/b]\n"
						else:
							choices_text += "-> "+i+"\n"
				else:
					choices_text += "- [b]"+info['text']+"[/b]\n"
				history_item.call(&'load_info', choices_text)

		get_history_log().add_child(history_item)

	if scroll_to_bottom:
		scroll_to_bottom_flag = true

	#get_show_history_button().hide()
	get_hide_history_button().visible = show_close_button
	get_history_box().show()
	nine_patch_rect.show()


func _on_hide_history_pressed() -> void:
	DialogicUtil.autoload().paused = false
	get_history_box().hide()
	nine_patch_rect.hide()
	get_hide_history_button().hide()
	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	get_show_history_button().visible = show_open_button and history_subsystem.get(&'simple_history_enabled')

func _on_free_action_start():
	_on_textbox_visible_changed(false)

func _on_free_action_end(_npc_type: GameEvents.NpcTypes, _free_action_component: HSceneFreeActionComponent):
	_on_textbox_visible_changed(true)

func _on_textbox_visible_changed(vis: bool):
	get_show_history_button().visible = vis

func _input(event: InputEvent) -> void:
	if GameEvents.get_window_state("safe_stage_h_action") or GameEvents.get_window_state("h_action"):
		return
	if get_history_box().visible:
		# [KR] 히스토리 박스가 실제로 열려 있을 때만 닫기 입력을 처리한다.
		#      (전환 중 등 박스가 닫힌 상태에서 action/esc가 _on_hide_history_pressed를 호출해
		#       Dialogic.paused를 풀어버려, 프리액션 진입 중 타임라인이 진행되는 버그 방지)
		##화면 밖 클릭시 꺼지게
		if event is InputEventMouseButton:
			var ev = event as InputEventMouseButton
			if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				if not get_history_box().get_global_rect().has_point(ev.position):
					_on_hide_history_pressed()
					get_viewport().set_input_as_handled()
		elif event.is_action_pressed("action") or event.is_action_pressed("esc"):
			_on_hide_history_pressed()
			get_viewport().set_input_as_handled()
		elif event.is_action("ui_up", true) or event.is_action("ui_down", true) \
		or event.is_action("move_up", true) or event.is_action("move_down", true):
			get_viewport().set_input_as_handled()
	elif not TransitionScreen.is_transition:
		# [KR] 박스가 닫혀 있고 전환 중이 아닐 때만 히스토리 열기 입력을 처리한다.
		if event.is_action_pressed("dialogic_history"):
			_on_show_history_pressed()
			get_viewport().set_input_as_handled()
