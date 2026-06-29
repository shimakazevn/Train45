extends Panel
class_name TutorialPanel

@export var tuto_manager: TutoManager
@onready var description: Label = %Description
@onready var texture: TextureRect = %Texture
@onready var arrow_next: Button = $ArrowNext
@onready var arrow_prev: Button = $ArrowPrev
@onready var confirm_button: Button = $ConfirmButton

var current_tuto : Tutos
var current_page: int = 0

func open_tuto(id: String):
	if not arrow_next.visibility_changed.is_connected(_on_changed_visible):
		arrow_next.visibility_changed.connect(_on_changed_visible.bind(arrow_next))
	if not arrow_prev.visibility_changed.is_connected(_on_changed_visible):
		arrow_prev.visibility_changed.connect(_on_changed_visible.bind(arrow_prev))
	if tuto_manager.tuto_data.has(id):
		current_tuto = tuto_manager.tuto_data[id] as Tutos
		
		current_page = 0
		update_ui(current_page)
	else:
		push_warning("%s 가 없습니다"%id)

func update_ui(_page: int):
	description.text = ""
	texture.texture = null

	description.text = current_tuto.tuto_pages[current_page].description
	if current_tuto.tuto_pages[current_page].texture:
		texture.texture = current_tuto.tuto_pages[current_page].texture

	# 기본 버튼 상태 초기화
	arrow_next.hide()
	arrow_prev.hide()
	confirm_button.hide()

	var page_count = current_tuto.tuto_pages.size()

	if page_count <= 1:
		# 단 한 장일 경우
		confirm_button.show()
		confirm_button.grab_focus()
	elif _page == 0:
		# 첫 페이지
		arrow_next.show()
		confirm_button.hide()
		arrow_next.grab_focus()
	elif _page == page_count - 1:
		# 마지막 페이지
		arrow_prev.show()
		confirm_button.show()
		confirm_button.grab_focus()
	else:
		# 중간 페이지
		arrow_next.show()
		arrow_prev.show()
		arrow_next.grab_focus()

func _on_changed_visible(button: Control):
	if button.visible == false and button.has_focus():
		set_valid_focus(button)

func set_valid_focus(from_button: Button):
	var candidates = [arrow_next, arrow_prev, confirm_button]
	for btn in candidates:
		if btn.visible and btn != from_button:
			btn.grab_focus()
			return

func _on_arrow_next_pressed() -> void:
	if TransitionScreen.is_transition or ChapterScreen.is_playing or LoadingScreen.is_active:
		return
	current_page += 1
	update_ui(current_page)

func _on_arrow_prev_pressed() -> void:
	if TransitionScreen.is_transition or ChapterScreen.is_playing or LoadingScreen.is_active:
		return
	current_page -= 1
	update_ui(current_page)

func set_close():
	if arrow_next.visibility_changed.is_connected(_on_changed_visible):
		arrow_next.visibility_changed.disconnect(_on_changed_visible)
	if arrow_prev.visibility_changed.is_connected(_on_changed_visible):
		arrow_prev.visibility_changed.disconnect(_on_changed_visible)
