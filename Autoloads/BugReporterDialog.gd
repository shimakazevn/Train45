extends CanvasLayer

signal send_pressed(data: Dictionary)
signal cancelled

@onready var thumb_rect: TextureRect = %ThumbRect
@onready var info_label: Label = %InfoLabel
@onready var tester_name_input: LineEdit = %TesterNameInput
@onready var priority_option: OptionButton = %PriorityOption
@onready var bug_type_option: OptionButton = %BugTypeOption
@onready var repro_option: OptionButton = %ReproOption
@onready var desc_input: TextEdit = %DescInput
@onready var steps_input: TextEdit = %StepsInput
@onready var status_label: Label = %StatusLabel
@onready var cancel_btn: Button = %CancelButton
@onready var send_btn: Button = %SendButton

const PRIORITIES = ["D", "C", "B", "A", "S"]
const BUG_TYPES = ["Gameplay", "UI", "Crash", "Performance", "Audio", "Other"]
const REPRO_RATES = ["Always", "Sometimes", "Only once", "Unconfirmed"]
const CONFIG_PATH = "user://bug_reporter.cfg"
const CONFIG_SECTION = "reporter"

func _ready() -> void:
	for p in PRIORITIES:
		priority_option.add_item(p)
	priority_option.selected = 1  # default: C

	for t in BUG_TYPES:
		bug_type_option.add_item(t)

	for r in REPRO_RATES:
		repro_option.add_item(r)

	cancel_btn.pressed.connect(func(): cancelled.emit())
	send_btn.pressed.connect(_on_send_pressed)

func _load_saved_name() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		tester_name_input.text = cfg.get_value(CONFIG_SECTION, "tester_name", "")

func _save_name(_name: String) -> void:
	var cfg = ConfigFile.new()
	cfg.load(CONFIG_PATH)
	cfg.set_value(CONFIG_SECTION, "tester_name", _name)
	cfg.save(CONFIG_PATH)

func _on_send_pressed() -> void:
	var tester_name = tester_name_input.text.strip_edges()
	if not tester_name.is_empty():
		_save_name(tester_name)
	send_pressed.emit({
		"description": desc_input.text.strip_edges(),
		"tester_name": tester_name,
		"priority": PRIORITIES[priority_option.selected],
		"bug_type": BUG_TYPES[bug_type_option.selected],
		"steps": steps_input.text.strip_edges(),
		"reproducibility": REPRO_RATES[repro_option.selected],
	})

func setup(screenshot: PackedByteArray, info_text: String) -> void:
	if screenshot.size() > 0:
		var img = Image.new()
		img.load_png_from_buffer(screenshot)
		thumb_rect.texture = ImageTexture.create_from_image(img)
	info_label.text = info_text
	_load_saved_name()

func set_sending(sending: bool, status_text: String) -> void:
	status_label.text = status_text
	send_btn.disabled = sending
	cancel_btn.disabled = sending
