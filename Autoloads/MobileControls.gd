class_name MobileControlsLayer
extends CanvasLayer

## Lớp phủ nút cảm ứng ảo cho bản mobile/touch (D-pad, nút hành động, tiện ích).
## Tự ẩn khi ở menu/hội thoại/tạm dừng; đổi layout khi vào H-scene.
## Nâng cấp: cache texture, tự căn lại khi xoay/đổi kích thước màn hình,
## scale theo màn hình (DPI-independent), rung haptic khi nhấn.

# ── Hằng số tinh chỉnh (đổi ở đây nếu muốn) ─────────────────────────────
const REFERENCE_SHORT_SIDE := 720.0   ## Cạnh ngắn màn hình tham chiếu → scale = 1.0
const UI_SCALE_MIN := 0.8
const UI_SCALE_MAX := 2.2
const FADE_SPEED := 5.0                ## Tốc độ fade in/out lớp nút
const ACTIVE_OPACITY := 1.0            ## Độ mờ khi hiện (0..1)
const HAPTIC_MS := 18                  ## Rung khi nhấn nút hành động (0 = tắt)
const TARGET_RATIO := 16.0 / 9.0

# Màu nút
const COLOR_ACTION := Color(1.0, 0.72, 0.18)
const COLOR_SHIFT := Color(0.22, 0.65, 1.0)
const COLOR_UTILITY := Color(0.8, 0.8, 0.85)
const COLOR_DPAD := Color(0.85, 0.85, 0.85)
const COLOR_EXIT := Color(1.0, 0.35, 0.35)

const MENU_HINTS := ["menu", "logo", "intro", "credit", "stage_picker", "recollection", "prologue"]
const SIDE_BAR_MIN := 60.0   ## Dải đen 2 bên rộng >= giá trị này (px) thì đặt nút vào đó

# ── Trạng thái ──────────────────────────────────────────────────────────
var main_container: Control
var gameplay_container: Control
var hscene_container: Control
var target_opacity := 0.0

var _lb_top := 0.0
var _lb_bottom := 0.0
var _lb_left := 0.0    ## Dải đen trái (pillarbox) khi màn hình rộng hơn 16:9
var _lb_right := 0.0   ## Dải đen phải
var _ui_scale := 1.0
var _enabled := false
var _last_window_size := Vector2i.ZERO
var _tex_cache: Dictionary = {}        ## key -> ImageTexture (tái dùng cho nút trùng)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var is_mobile := OS.get_name() in ["Android", "iOS"]
	var is_touch := DisplayServer.is_touchscreen_available()
	if not (is_mobile or is_touch):
		visible = false
		set_process(false)
		return

	_enabled = true
	_rebuild()
	# Tự căn lại khi đổi kích thước / xoay màn hình.
	get_tree().root.size_changed.connect(_on_window_resized)


func _on_window_resized() -> void:
	if not _enabled:
		return
	var sz := DisplayServer.window_get_size()
	if sz == _last_window_size:
		return
	_tex_cache.clear()   # kích thước nút đổi theo scale → cache cũ không dùng lại
	_rebuild()


## Dựng (hoặc dựng lại) toàn bộ lớp nút theo kích thước màn hình hiện tại.
func _rebuild() -> void:
	_calculate_layout()

	if is_instance_valid(main_container):
		main_container.queue_free()

	main_container = _new_full_rect_control()
	main_container.modulate.a = target_opacity
	add_child(main_container)

	gameplay_container = _new_full_rect_control()
	main_container.add_child(gameplay_container)

	hscene_container = _new_full_rect_control()
	main_container.add_child(hscene_container)

	_setup_buttons()


func _new_full_rect_control() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _calculate_layout() -> void:
	var size := DisplayServer.window_get_size()
	_last_window_size = size

	# Scale theo cạnh ngắn của màn hình để nút không quá bé/quá to trên máy nét cao.
	var short_side := float(min(size.x, size.y))
	_ui_scale = clampf(short_side / REFERENCE_SHORT_SIDE, UI_SCALE_MIN, UI_SCALE_MAX)

	# Viền đen quanh khung game 16:9:
	#  - Màn hình CAO hơn 16:9 (dọc)  → letterbox trên/dưới.
	#  - Màn hình RỘNG hơn 16:9 (đa số ĐT ngang) → pillarbox trái/phải.
	_lb_top = 0.0
	_lb_bottom = 0.0
	_lb_left = 0.0
	_lb_right = 0.0
	var current_ratio := float(size.x) / float(size.y)
	if current_ratio < TARGET_RATIO:
		var game_height := float(size.x) / TARGET_RATIO
		_lb_top = (float(size.y) - game_height) / 2.0
		_lb_bottom = _lb_top
	elif current_ratio > TARGET_RATIO:
		var game_width := float(size.y) * TARGET_RATIO
		_lb_left = (float(size.x) - game_width) / 2.0
		_lb_right = _lb_left


## Nhân giá trị thiết kế theo scale (letterbox thì KHÔNG scale vì là px màn hình thật).
func _s(v: float) -> float:
	return v * _ui_scale


func _process(_delta: float) -> void:
	var current_scene := get_tree().current_scene
	if not current_scene:
		target_opacity = 0.0
		if is_instance_valid(main_container):
			main_container.modulate.a = 0.0
		visible = false
		return

	var scene_path := current_scene.scene_file_path.to_lower()
	var scene_name := current_scene.name.to_lower()

	var is_menu := false
	for hint in MENU_HINTS:
		if hint in scene_path or hint in scene_name:
			is_menu = true
			break

	var is_dialog := false
	if has_node("/root/Dialogic"):
		is_dialog = get_node("/root/Dialogic").current_timeline != null

	var is_paused := get_tree().paused

	var is_h_scene := false
	if has_node("/root/GameEvents") and has_node("/root/Constants"):
		var ge := get_node("/root/GameEvents")
		var c := get_node("/root/Constants")
		is_h_scene = ge.get_window_state(c.WINDOW_STATE_H_ACTION)

	var should_be_visible := false
	if is_h_scene:
		should_be_visible = not is_paused
	else:
		should_be_visible = not (is_menu or is_dialog or is_paused)

	if should_be_visible:
		visible = true
		target_opacity = move_toward(target_opacity, ACTIVE_OPACITY, _delta * FADE_SPEED)
		gameplay_container.visible = not is_h_scene
		hscene_container.visible = is_h_scene
	else:
		target_opacity = move_toward(target_opacity, 0.0, _delta * FADE_SPEED)
		if target_opacity <= 0.0:
			visible = false

	main_container.modulate.a = target_opacity


func _setup_buttons() -> void:
	# Ưu tiên đặt nút vào 2 dải đen bên (pillarbox) nếu đủ rộng — không che gameplay.
	if _lb_left >= SIDE_BAR_MIN:
		_setup_gameplay_side_bars()
	else:
		_setup_gameplay_in_frame()
	_setup_hscene()


## Bố cục tận dụng 2 dải đen 2 bên (điện thoại ngang rộng hơn 16:9).
## D-pad giữa dải TRÁI, nút hành động giữa dải PHẢI, tiện ích xếp dọc đỉnh dải trái.
func _setup_gameplay_side_bars() -> void:
	var btn_w := 46.0
	var btn_h := 24.0
	var left_cx := _lb_left * 0.5      # tâm dải trái (tính từ mép trái)
	var right_cx := -_lb_right * 0.5   # tâm dải phải (tính từ mép phải)

	# D-pad: chụm giữa dải trái, tầm dưới cho ngón cái.
	var dpad_y := _s(140.0)
	var gap := _s(30.0)
	_add_dpad_button(gameplay_container, "move_up", Vector2(left_cx, -dpad_y - gap), 25.0, "↑", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)
	_add_dpad_button(gameplay_container, "move_down", Vector2(left_cx, -dpad_y + gap), 25.0, "↓", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)
	_add_dpad_button(gameplay_container, "move_left", Vector2(left_cx - gap, -dpad_y), 25.0, "←", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)
	_add_dpad_button(gameplay_container, "move_right", Vector2(left_cx + gap, -dpad_y), 25.0, "→", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)

	# Nút hành động: giữa dải phải, tầm dưới.
	_add_utility_button(gameplay_container, "action", Vector2(right_cx, -_s(120.0)), btn_w, btn_h, "DÒ", Control.PRESET_BOTTOM_RIGHT, COLOR_ACTION)
	_add_utility_button(gameplay_container, "shift", Vector2(right_cx, -_s(175.0)), 56.0, btn_h, "THOẠI", Control.PRESET_BOTTOM_RIGHT, COLOR_SHIFT)

	# Tiện ích: xếp dọc ở đỉnh dải trái.
	_add_utility_button(gameplay_container, "esc", Vector2(left_cx, _s(20.0)), btn_w, btn_h, "ESC", Control.PRESET_TOP_LEFT, COLOR_EXIT)
	_add_utility_button(gameplay_container, "testkey", Vector2(left_cx, _s(52.0)), btn_w, btn_h, "XEM", Control.PRESET_TOP_LEFT, COLOR_UTILITY)
	_add_utility_button(gameplay_container, "return_base", Vector2(left_cx, _s(84.0)), btn_w, btn_h, "VỀ", Control.PRESET_TOP_LEFT, COLOR_UTILITY)


## Bố cục dự phòng khi KHÔNG có dải bên (đúng 16:9 hoặc màn hình dọc → letterbox trên/dưới).
func _setup_gameplay_in_frame() -> void:
	var btn_w := 46.0
	var btn_h := 24.0
	var col_x := -35.0
	var dpad_x := 100.0
	var dpad_y := 120.0
	var gap := 32.0

	_add_dpad_button(gameplay_container, "move_up", Vector2(_s(dpad_x), -_s(dpad_y + gap) - _lb_bottom), 25.0, "↑", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)
	_add_dpad_button(gameplay_container, "move_down", Vector2(_s(dpad_x), -_s(dpad_y - gap) - _lb_bottom), 25.0, "↓", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)
	_add_dpad_button(gameplay_container, "move_left", Vector2(_s(dpad_x - gap), -_s(dpad_y) - _lb_bottom), 25.0, "←", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)
	_add_dpad_button(gameplay_container, "move_right", Vector2(_s(dpad_x + gap), -_s(dpad_y) - _lb_bottom), 25.0, "→", Control.PRESET_BOTTOM_LEFT, COLOR_DPAD)

	_add_utility_button(gameplay_container, "action", Vector2(-_s(65.0), -_s(85.0) - _lb_bottom), btn_w, btn_h, "DÒ", Control.PRESET_BOTTOM_RIGHT, COLOR_ACTION)
	_add_utility_button(gameplay_container, "shift", Vector2(-_s(125.0), -_s(85.0) - _lb_bottom), 56.0, btn_h, "THOẠI", Control.PRESET_BOTTOM_RIGHT, COLOR_SHIFT)

	_add_utility_button(gameplay_container, "esc", Vector2(col_x, _s(15.0) + _lb_top * 0.5), btn_w, btn_h, "ESC", Control.PRESET_TOP_RIGHT, COLOR_EXIT)
	_add_utility_button(gameplay_container, "testkey", Vector2(col_x, _s(46.0) + _lb_top * 0.5), btn_w, btn_h, "XEM", Control.PRESET_TOP_RIGHT, COLOR_UTILITY)
	_add_utility_button(gameplay_container, "return_base", Vector2(col_x, _s(77.0) + _lb_top * 0.5), btn_w, btn_h, "VỀ", Control.PRESET_TOP_RIGHT, COLOR_UTILITY)


## Layout H-scene — mọi nút ngoài khung game (dùng dải bên nếu có, không thì mép).
func _setup_hscene() -> void:
	var btn_w := 46.0
	var btn_h := 24.0
	var side := _lb_left if _lb_left >= SIDE_BAR_MIN else 0.0
	var lx := (side * 0.5) if side > 0.0 else _s(45.0)

	_add_dpad_button(hscene_container, "move_down", Vector2(_s(135.0), _s(15.0)), 32.0, "XUỐNG", Control.PRESET_BOTTOM_LEFT, COLOR_ACTION)
	_add_dpad_button(hscene_container, "move_up", Vector2(_s(65.0), _s(15.0)), 26.0, "LÊN", Control.PRESET_BOTTOM_LEFT, COLOR_SHIFT)

	_add_utility_button(hscene_container, "esc", Vector2(lx if side > 0.0 else _s(45.0), _s(15.0)), 58.0, btn_h, "THOÁT", Control.PRESET_TOP_LEFT, COLOR_EXIT)
	_add_utility_button(hscene_container, "scroll_down", Vector2(_s(110.0), _s(15.0)), btn_w, btn_h, "RỘNG", Control.PRESET_TOP_LEFT, COLOR_UTILITY)
	_add_utility_button(hscene_container, "scroll_up", Vector2(_s(170.0), _s(15.0)), btn_w, btn_h, "CẬN", Control.PRESET_TOP_LEFT, COLOR_UTILITY)


# ── Tạo nút ─────────────────────────────────────────────────────────────

## Nút tròn (D-pad / di chuyển). Không rung để tránh buzz liên tục khi giữ.
func _add_dpad_button(parent_node: Control, action_name: String, center: Vector2, radius: float, label_text: String, anchor_preset: int, theme_color: Color) -> void:
	var r := _s(radius)
	var tsb := _make_button(
		parent_node, action_name, anchor_preset, center - Vector2(r, r),
		_get_circle_texture(r, theme_color, false),
		_get_circle_texture(r, theme_color, true),
		false)
	var font_size := int(r * (0.35 if label_text.length() > 3 else 0.45))
	tsb.add_child(_make_label(label_text, Vector2(r * 2.0, r * 2.0), 4, font_size))


## Nút chữ nhật bo góc (hành động / tiện ích). Có rung haptic khi nhấn.
func _add_utility_button(parent_node: Control, action_name: String, center: Vector2, w: float, h: float, label_text: String, anchor_preset: int, theme_color: Color) -> void:
	var sw := _s(w)
	var sh := _s(h)
	var tsb := _make_button(
		parent_node, action_name, anchor_preset, center - Vector2(sw * 0.5, sh * 0.5),
		_get_rect_texture(sw, sh, _s(6.0), theme_color, false),
		_get_rect_texture(sw, sh, _s(6.0), theme_color, true),
		true)
	var font_size := 11
	if label_text.length() >= 4:
		font_size = 9
	elif label_text.length() == 3:
		font_size = 10
	tsb.add_child(_make_label(label_text, Vector2(sw, sh), 3, int(_s(font_size))))


func _make_button(parent_node: Control, action_name: String, anchor_preset: int, top_left: Vector2, tex_normal: Texture2D, tex_pressed: Texture2D, haptic: bool) -> TouchScreenButton:
	var tsb := TouchScreenButton.new()
	tsb.action = action_name
	tsb.texture_normal = tex_normal
	tsb.texture_pressed = tex_pressed
	tsb.position = top_left
	if haptic and HAPTIC_MS > 0:
		tsb.pressed.connect(func(): Input.vibrate_handheld(HAPTIC_MS))

	var anchor_node := Control.new()
	anchor_node.set_anchors_and_offsets_preset(anchor_preset)
	parent_node.add_child(anchor_node)
	anchor_node.add_child(tsb)
	return tsb


func _make_label(text: String, box: Vector2, outline: int, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = box
	label.position = Vector2.ZERO
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_font_size_override("font_size", max(1, font_size))
	return label


# ── Texture (có cache) ───────────────────────────────────────────────────

func _get_circle_texture(radius: float, theme_color: Color, is_pressed: bool) -> ImageTexture:
	var key := "c|%d|%d|%d|%d|%d" % [int(radius), int(theme_color.r * 255), int(theme_color.g * 255), int(theme_color.b * 255), int(is_pressed)]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var tex := _generate_circle_texture(radius, theme_color, is_pressed)
	_tex_cache[key] = tex
	return tex


func _get_rect_texture(w: float, h: float, corner_radius: float, theme_color: Color, is_pressed: bool) -> ImageTexture:
	var key := "r|%d|%d|%d|%d|%d|%d|%d" % [int(w), int(h), int(corner_radius), int(theme_color.r * 255), int(theme_color.g * 255), int(theme_color.b * 255), int(is_pressed)]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var tex := _generate_rounded_rect_texture(w, h, corner_radius, theme_color, is_pressed)
	_tex_cache[key] = tex
	return tex


func _generate_circle_texture(radius: float, theme_color: Color, is_pressed: bool) -> ImageTexture:
	var size := maxi(1, int(radius * 2.0))
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := radius

	var fill_color := theme_color
	fill_color.a = 0.52 if is_pressed else 0.16
	var border_color := theme_color
	border_color.a = 0.95 if is_pressed else 0.42

	for x in range(size):
		for y in range(size):
			var dx := x - center + 0.5
			var dy := y - center + 0.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist < radius:
				var edge_factor := clampf((radius - dist) / 1.5, 0.0, 1.0)
				var border_width := 2.0
				var color := fill_color
				if dist >= radius - border_width:
					var t := (dist - (radius - border_width)) / border_width
					color = fill_color.lerp(border_color, t)
				else:
					var grad := dist / (radius - border_width)
					color.a = fill_color.a * (0.35 + 0.65 * grad)
				color.a *= edge_factor
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func _generate_rounded_rect_texture(w: float, h: float, corner_radius: float, theme_color: Color, is_pressed: bool) -> ImageTexture:
	var iw := maxi(1, int(w))
	var ih := maxi(1, int(h))
	var img := Image.create(iw, ih, false, Image.FORMAT_RGBA8)

	var fill_color := theme_color
	fill_color.a = 0.50 if is_pressed else 0.15
	var border_color := theme_color
	border_color.a = 0.90 if is_pressed else 0.40
	var border_width := 1.5

	for x in range(iw):
		for y in range(ih):
			var dx := 0.0
			var dy := 0.0
			if x < corner_radius:
				dx = corner_radius - x
			elif x > w - corner_radius:
				dx = x - (w - corner_radius)
			if y < corner_radius:
				dy = corner_radius - y
			elif y > h - corner_radius:
				dy = y - (h - corner_radius)

			var is_corner := dx > 0.0 and dy > 0.0
			var dist := sqrt(dx * dx + dy * dy) if is_corner else 0.0
			if not is_corner or dist < corner_radius:
				var edge_factor := 1.0
				if is_corner:
					edge_factor = clampf((corner_radius - dist) / 1.5, 0.0, 1.0)
				var is_border := false
				if is_corner:
					is_border = dist >= corner_radius - border_width
				else:
					is_border = x < border_width or x >= w - border_width or y < border_width or y >= h - border_width
				var color := fill_color
				if is_border:
					color = border_color
				else:
					var cx := absf(x - w / 2.0) / (w / 2.0)
					var cy := absf(y - h / 2.0) / (h / 2.0)
					color.a = fill_color.a * (0.4 + 0.6 * maxf(cx, cy))
				color.a *= edge_factor
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
