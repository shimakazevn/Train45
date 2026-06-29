extends Control

@export var tuto_list_button: PackedScene
@onready var tuto_list_container: VBoxContainer = %TutoListContainer

@onready var tuto_texture: TextureRect = %TutoTexture
@onready var tuto_discription: Label = %TutoDiscription
@onready var description_scroll: ScrollContainer = %DescriptionScroll
@onready var pad_container: Control = %PadContainer

var current_tutos: Tutos
var current_tutos_page: int = 0

@onready var arrows: Control = %Arrows
@onready var arrow_next: Button = %ArrowNext
@onready var arrow_prev: Button = %ArrowPrev
@onready var exit_button: Button = %ExitButton


@onready var current_page: Label = %CurrentPage

const SCROLL_SPEED: int = 50

var test_read_events: Array[String] = [
	"anomaly_ghost_h",
	"tuto_base_h_action",
	"base_h_event",
]

func _ready() -> void:
	await _queue_clean()
	_add_readed_tuto_list()
	arrow_next.pressed.connect(func(): _set_page(current_tutos_page + 1))
	arrow_prev.pressed.connect(func(): _set_page(current_tutos_page - 1))
	exit_button.pressed.connect(func(): self.queue_free())

func _queue_clean():
	for i in tuto_list_container.get_children():
		i.queue_free()
		await i.tree_exited

## metadata에서 read event에 존재하는 tuto_ 의 아이디를 tuto_list_button 을 인스턴스하여 tuto_list_container에 add_child한다
func _add_readed_tuto_list():
	var tutos_dict: Dictionary = {}
	for r in TrainUtil.get_res_from_path("res://Gameplay/GameData/Tutorials/"):
		if r is Tutos and r.id != "":
			tutos_dict[r.id] = r

	var source: Array = test_read_events if Constants.TUTORIAL_BOOK_TEST else MetaProgression.get_read_event()
	for event_name in source:
		if not tutos_dict.has(event_name):
			continue
		var btn: TutorialBookListButton = tuto_list_button.instantiate()
		btn.tutos = tutos_dict[event_name]
		tuto_list_container.add_child(btn)
		btn.pressed.connect(_on_tuto_button_pressed.bind(btn))

	var first := tuto_list_container.get_child(0) as TutorialBookListButton
	if first:
		first.grab_focus()
		_on_tuto_button_pressed(first)

func _on_tuto_button_pressed(tuto_btn: TutorialBookListButton):
	if current_tutos == tuto_btn.tutos:
		return
	for btn in tuto_list_container.get_children():
		btn.button_pressed = btn == tuto_btn
	current_tutos = tuto_btn.tutos
	_set_page(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		get_viewport().set_input_as_handled()
		queue_free()
		return
	## 입력맵 move_left는 이전 페이지, move_right는 다음 페이지
	if not current_tutos:
		return
	if event.is_action_pressed("move_left"):
		_set_page(current_tutos_page - 1)
	elif event.is_action_pressed("move_right"):
		_set_page(current_tutos_page + 1)
	elif event.is_action_pressed("sub_scroll_down"):
		description_scroll.scroll_vertical += int(SCROLL_SPEED)
	elif event.is_action_pressed("sub_scroll_up"):
		description_scroll.scroll_vertical -= int(SCROLL_SPEED)
		

func _set_page(next_page: int):
	current_tutos_page = clampi(next_page, 0, current_tutos.tuto_pages.size() - 1)
	var page: TutoPage = current_tutos.tuto_pages[current_tutos_page]
	tuto_texture.texture = page.texture
	tuto_discription.text = page.description
	_update_arrows()
	await get_tree().process_frame
	var bar := description_scroll.get_v_scroll_bar()
	pad_container.visible = bar.max_value > bar.page

func _update_arrows():
	var page_count := current_tutos.tuto_pages.size()
	arrow_prev.visible = current_tutos_page > 0
	arrow_next.visible = current_tutos_page < page_count - 1
	current_page.text = "%d/%d" % [current_tutos_page + 1, page_count]
