extends CanvasLayer

var main_container: Control
var gameplay_container: Control
var hscene_container: Control
var target_opacity = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Only show on Android, iOS or devices with touchscreen support
	var is_mobile = OS.get_name() in ["Android", "iOS"]
	var is_touch = DisplayServer.is_touchscreen_available()
	if not (is_mobile or is_touch):
		visible = false
		set_process(false)
		return
		
	# Setup main container for smooth fade transitions
	main_container = Control.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.modulate.a = 0.0
	add_child(main_container)
	
	# Setup sub-containers for modular layouts
	gameplay_container = Control.new()
	gameplay_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameplay_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(gameplay_container)
	
	hscene_container = Control.new()
	hscene_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hscene_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(hscene_container)
	
	# Setup all virtual buttons
	_setup_buttons()

func _process(delta):
	var current_scene = get_tree().current_scene
	if not current_scene:
		target_opacity = 0.0
		main_container.modulate.a = 0.0
		self.visible = false
		return

	var scene_path = current_scene.scene_file_path.to_lower()
	var scene_name = current_scene.name.to_lower()

	# Hide on menu screens, options, recollection room, credits, prologue
	var is_menu = ("menu" in scene_path) or ("menu" in scene_name) or ("logo" in scene_name) or ("intro" in scene_name) or ("credit" in scene_name) or ("stage_picker" in scene_path) or ("stage_picker" in scene_name) or ("recollection" in scene_path) or ("prologue" in scene_path)
	
	# Hide during Dialogic dialogue timelines
	var is_dialog = false
	if has_node("/root/Dialogic"):
		is_dialog = get_node("/root/Dialogic").current_timeline != null
		
	# Hide if the game is paused
	var is_paused = get_tree().paused
	
	# Check if H-scene is active using the game's official window state
	var is_h_scene = false
	if has_node("/root/GameEvents") and has_node("/root/Constants"):
		var ge = get_node("/root/GameEvents")
		var c = get_node("/root/Constants")
		is_h_scene = ge.get_window_state(c.WINDOW_STATE_H_ACTION)
		
	# Determine visibility based on whether H-scene is active
	var should_be_visible = false
	if is_h_scene:
		should_be_visible = not is_paused
	else:
		should_be_visible = not (is_menu or is_dialog or is_paused)
	
	if should_be_visible:
		self.visible = true
		target_opacity = move_toward(target_opacity, 1.0, delta * 5.0)
		
		# Toggle layouts dynamically
		if is_h_scene:
			gameplay_container.visible = false
			hscene_container.visible = true
		else:
			gameplay_container.visible = true
			hscene_container.visible = false
	else:
		target_opacity = move_toward(target_opacity, 0.0, delta * 5.0)
		if target_opacity <= 0.0:
			self.visible = false
			
	main_container.modulate.a = target_opacity

func _setup_buttons():
	var action_color = Color(1.0, 0.72, 0.18)   # Glow Gold for Primary Action
	var shift_color = Color(0.22, 0.65, 1.0)    # Glow Cyan/Blue for Dash/Talk
	var utility_color = Color(0.8, 0.8, 0.85)   # Clean Silver for Secondary utilities
	var dpad_color = Color(0.85, 0.85, 0.85)    # Silver/White
	var exit_color = Color(1.0, 0.35, 0.35)    # Soft glowing Red for exit/escape button
	var y_pos = 30.0                           # Shared vertical position for top row elements
	
	# =========================================================================
	# 1. NORMAL GAMEPLAY LAYOUT (gameplay_container)
	# =========================================================================
	# D-Pad (Bottom Left) - More compact and shifted closer to corner
	var dpad_center_x = 150.0
	var dpad_offset_y = 120.0
	var dpad_radius = 21.0
	var dpad_gap = 30.0
	
	_add_virtual_button(gameplay_container, "move_up", Vector2(dpad_center_x, -dpad_offset_y - dpad_gap), dpad_radius, "↑", Control.PRESET_BOTTOM_LEFT, dpad_color)
	_add_virtual_button(gameplay_container, "move_down", Vector2(dpad_center_x, -dpad_offset_y + dpad_gap), dpad_radius, "↓", Control.PRESET_BOTTOM_LEFT, dpad_color)
	_add_virtual_button(gameplay_container, "move_left", Vector2(dpad_center_x - dpad_gap, -dpad_offset_y), dpad_radius, "←", Control.PRESET_BOTTOM_LEFT, dpad_color)
	_add_virtual_button(gameplay_container, "move_right", Vector2(dpad_center_x + dpad_gap, -dpad_offset_y), dpad_radius, "→", Control.PRESET_BOTTOM_LEFT, dpad_color)
	
	# Primary circular action buttons (Bottom Right) - Shrunk & lifted slightly to clear the ticket bar
	_add_virtual_button(gameplay_container, "action", Vector2(-65.0, -85.0), 28.0, "DÒ", Control.PRESET_BOTTOM_RIGHT, action_color)
	_add_virtual_button(gameplay_container, "shift", Vector2(-125.0, -85.0), 22.0, "THOẠI", Control.PRESET_BOTTOM_RIGHT, shift_color)
	
	# Utility buttons (Top Right vertical column to prevent keyboard helper overlaps)
	# Sleek horizontal row is replaced with a right-aligned vertical strip
	var btn_w = 46.0
	var btn_h = 24.0
	var col_x = -35.0
	
	_add_utility_button(gameplay_container, "esc", Vector2(col_x, 25.0), btn_w, btn_h, "ESC", Control.PRESET_TOP_RIGHT, exit_color)
	_add_utility_button(gameplay_container, "shotcut_kankan", Vector2(col_x, 56.0), btn_w, btn_h, "NAVI", Control.PRESET_TOP_RIGHT, utility_color)
	_add_utility_button(gameplay_container, "shotcut_inventory", Vector2(col_x, 87.0), btn_w, btn_h, "KHO", Control.PRESET_TOP_RIGHT, utility_color)
	_add_utility_button(gameplay_container, "testkey", Vector2(col_x, 118.0), btn_w, btn_h, "XEM", Control.PRESET_TOP_RIGHT, utility_color)
	_add_utility_button(gameplay_container, "return_base", Vector2(col_x, 149.0), btn_w, btn_h, "VỀ", Control.PRESET_TOP_RIGHT, utility_color)

	# =========================================================================
	# 2. H-SCENE LAYOUT (hscene_container)
	# =========================================================================
	# Speed control and Thrust action (Bottom Left to clear the right side HUD)
	_add_virtual_button(hscene_container, "move_down", Vector2(135.0, -65.0), 32.0, "XUỐNG", Control.PRESET_BOTTOM_LEFT, action_color)
	_add_virtual_button(hscene_container, "move_up", Vector2(65.0, -65.0), 26.0, "LÊN", Control.PRESET_BOTTOM_LEFT, shift_color)
	
	# Top Left row for Exit and Zoom in H-scene (keeps the right side X-Ray clean)
	_add_utility_button(hscene_container, "esc", Vector2(45.0, y_pos), 58.0, btn_h, "THOÁT", Control.PRESET_TOP_LEFT, exit_color)
	_add_utility_button(hscene_container, "scroll_down", Vector2(110.0, y_pos), btn_w, btn_h, "RỘNG", Control.PRESET_TOP_LEFT, utility_color)
	_add_utility_button(hscene_container, "scroll_up", Vector2(170.0, y_pos), btn_w, btn_h, "CẬN", Control.PRESET_TOP_LEFT, utility_color)

func _add_virtual_button(parent_node: Control, action_name: String, offset: Vector2, radius: float, label_text: String, anchor_preset: int, theme_color: Color):
	var tex_normal = _generate_circle_texture(radius, theme_color, false)
	var tex_pressed = _generate_circle_texture(radius, theme_color, true)
	
	var tsb = TouchScreenButton.new()
	tsb.action = action_name
	tsb.texture_normal = tex_normal
	tsb.texture_pressed = tex_pressed
	tsb.position = offset - Vector2(radius, radius)
	
	var anchor_node = Control.new()
	anchor_node.set_anchors_and_offsets_preset(anchor_preset)
	parent_node.add_child(anchor_node)
	anchor_node.add_child(tsb)
	
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(radius * 2.0, radius * 2.0)
	label.position = Vector2.ZERO
	
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	
	var font_size = int(radius * 0.45)
	if label_text.length() > 3:
		font_size = int(radius * 0.35)
	label.add_theme_font_size_override("font_size", font_size)
	
	tsb.add_child(label)

func _add_utility_button(parent_node: Control, action_name: String, offset: Vector2, w: float, h: float, label_text: String, anchor_preset: int, theme_color: Color):
	var tex_normal = _generate_rounded_rect_texture(w, h, 6.0, theme_color, false)
	var tex_pressed = _generate_rounded_rect_texture(w, h, 6.0, theme_color, true)
	
	var tsb = TouchScreenButton.new()
	tsb.action = action_name
	tsb.texture_normal = tex_normal
	tsb.texture_pressed = tex_pressed
	tsb.position = offset - Vector2(w / 2.0, h / 2.0)
	
	var anchor_node = Control.new()
	anchor_node.set_anchors_and_offsets_preset(anchor_preset)
	parent_node.add_child(anchor_node)
	anchor_node.add_child(tsb)
	
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(w, h)
	label.position = Vector2.ZERO
	
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	
	var font_size = 11
	if label_text.length() >= 4:
		font_size = 9
	elif label_text.length() == 3:
		font_size = 10
	label.add_theme_font_size_override("font_size", font_size)
	
	tsb.add_child(label)

func _generate_circle_texture(radius: float, theme_color: Color, is_pressed: bool) -> ImageTexture:
	var size = int(radius * 2.0)
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = radius
	
	var fill_color = theme_color
	fill_color.a = 0.52 if is_pressed else 0.16
	
	var border_color = theme_color
	border_color.a = 0.95 if is_pressed else 0.42
	
	for x in range(size):
		for y in range(size):
			var dx = x - center + 0.5
			var dy = y - center + 0.5
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist < radius:
				var edge_factor = clamp((radius - dist) / 1.5, 0.0, 1.0)
				var border_width = 2.0
				var color = fill_color
				
				if dist >= radius - border_width:
					var t = (dist - (radius - border_width)) / border_width
					color = fill_color.lerp(border_color, t)
				else:
					var grad = dist / (radius - border_width)
					color.a = fill_color.a * (0.35 + 0.65 * grad)
				
				color.a *= edge_factor
				img.set_pixel(x, y, color)
				
	return ImageTexture.create_from_image(img)

func _generate_rounded_rect_texture(w: float, h: float, corner_radius: float, theme_color: Color, is_pressed: bool) -> ImageTexture:
	var img = Image.create(int(w), int(h), false, Image.FORMAT_RGBA8)
	
	var fill_color = theme_color
	fill_color.a = 0.50 if is_pressed else 0.15
	
	var border_color = theme_color
	border_color.a = 0.90 if is_pressed else 0.40
	
	var border_width = 1.5
	
	for x in range(int(w)):
		for y in range(int(h)):
			var dx = 0.0
			var dy = 0.0
			
			if x < corner_radius:
				dx = corner_radius - x
			elif x > w - corner_radius:
				dx = x - (w - corner_radius)
				
			if y < corner_radius:
				dy = corner_radius - y
			elif y > h - corner_radius:
				dy = y - (h - corner_radius)
				
			var is_corner = dx > 0.0 and dy > 0.0
			var dist = sqrt(dx*dx + dy*dy) if is_corner else 0.0
			
			if not is_corner or dist < corner_radius:
				var edge_factor = 1.0
				if is_corner:
					edge_factor = clamp((corner_radius - dist) / 1.5, 0.0, 1.0)
				
				var is_border = false
				if is_corner:
					is_border = dist >= corner_radius - border_width
				else:
					is_border = x < border_width or x >= w - border_width or y < border_width or y >= h - border_width
					
				var color = fill_color
				if is_border:
					color = border_color
				else:
					var cx = abs(x - w / 2.0) / (w / 2.0)
					var cy = abs(y - h / 2.0) / (h / 2.0)
					var edge_dist = max(cx, cy)
					color.a = fill_color.a * (0.4 + 0.6 * edge_dist)
					
				color.a *= edge_factor
				img.set_pixel(x, y, color)
				
	return ImageTexture.create_from_image(img)
