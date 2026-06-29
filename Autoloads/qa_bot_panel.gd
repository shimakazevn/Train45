extends PanelContainer

@onready var status_label: Label = %StatusLabel
@onready var toggle_button: Button = %ToggleButton
@onready var dialogue_check: CheckButton = %DialogueSkipCheck
@onready var tutorial_check: CheckButton = %TutorialCheck
@onready var h_scene_check: CheckButton = %HSceneCheck
@onready var anomaly_check: CheckButton = %AnomalyCheck
@onready var event_check: CheckButton = %EventCheck
@onready var run_clear_check: CheckButton = %RunClearCheck
@onready var earn_ticket_check: CheckButton = %EarnTicketCheck
@onready var ero_cheat_check: CheckButton = %EroCheatCheck
@onready var equip_all_check: CheckButton = %EquipAllCheck

var _bot: Node


func setup(bot: Node) -> void:
	_bot = bot
	dialogue_check.set_pressed_no_signal(bot.enable_dialogue_skip)
	tutorial_check.set_pressed_no_signal(bot.enable_tutorial)
	h_scene_check.set_pressed_no_signal(bot.enable_h_scene)
	anomaly_check.set_pressed_no_signal(bot.enable_anomaly)
	event_check.set_pressed_no_signal(bot.enable_event)
	run_clear_check.set_pressed_no_signal(bot.enable_run_clear)
	earn_ticket_check.set_pressed_no_signal(bot.enable_earn_ticket)
	ero_cheat_check.set_pressed_no_signal(bot.enable_ero_cheat)
	equip_all_check.set_pressed_no_signal(bot.enable_equip_all)

	toggle_button.pressed.connect(bot.toggle)
	dialogue_check.toggled.connect(func(v): bot.enable_dialogue_skip = v)
	tutorial_check.toggled.connect(func(v): bot.enable_tutorial = v)
	h_scene_check.toggled.connect(func(v): bot.enable_h_scene = v)
	anomaly_check.toggled.connect(func(v): bot.enable_anomaly = v)
	event_check.toggled.connect(func(v): bot.enable_event = v)
	run_clear_check.toggled.connect(func(v): bot.enable_run_clear = v)
	earn_ticket_check.toggled.connect(func(v): bot.enable_earn_ticket = v)
	ero_cheat_check.toggled.connect(func(v): bot.enable_ero_cheat = v)
	equip_all_check.toggled.connect(func(v): bot.enable_equip_all = v)

	update_status(bot.active, "IDLE")


func update_status(is_active: bool, phase_name: String) -> void:
	status_label.text = "상태: %s | 페이즈: %s" % ["ON" if is_active else "OFF", phase_name]
	toggle_button.text = "정지" if is_active else "시작"
