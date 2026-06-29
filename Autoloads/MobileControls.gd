extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Only show on Android, iOS or devices with touchscreen support
	var is_mobile = OS.get_name() in ["Android", "iOS"]
	var is_touch = DisplayServer.is_touchscreen_available()
	if not (is_mobile or is_touch):
		visible = false
		return
		
	# Setup all virtual buttons
	_setup_buttons()

func _setup_buttons():
	# D-Pad Button Definitions (Bottom Left)
	var dpad_center_x = 180.0
	var dpad_offset_y = 180.0
	var dpad_radius = 55.0
	var dpad_gap = 70.0
	
	_add_virtual_button("move_up", Vector2(dpad_center_x, -dpad_offset_y - dpad_gap), dpad_radius, "↑", Control.PRESET_BOTTOM_LEFT)
	_add_virtual_button("move_down", Vector2(dpad_center_x, -dpad_offset_y + dpad_gap), dpad_radius, "↓", Control.PRESET_BOTTOM_LEFT)
	_add_virtual_button("move_left", Vector2(dpad_center_x - dpad_gap, -dpad_offset_y), dpad_radius, "←", Control.PRESET_BOTTOM_LEFT)
	_add_virtual_button("move_right", Vector2(dpad_center_x + dpad_gap, -dpad_offset_y), dpad_radius, "→", Control.PRESET_BOTTOM_LEFT)
	
	# Action Button Definitions (Bottom Right)
	var act_offset_y = 150.0
	var act_gap = 120.0
	
	# Main Action Buttons (Primary)
	_add_virtual_button("action", Vector2(-130.0, -act_offset_y), 65.0, "DÒ\n(Space)", Control.PRESET_BOTTOM_RIGHT)
	_add_virtual_button("shift", Vector2(-130.0 - act_gap, -act_offset_y + 35.0), 55.0, "THOẠI\n(Shift)", Control.PRESET_BOTTOM_RIGHT)
	
	# Secondary utility buttons
	_add_virtual_button("shotcut_kankan", Vector2(-130.0, -act_offset_y - act_gap), 45.0, "NAVI\n(E)", Control.PRESET_BOTTOM_RIGHT)
	_add_virtual_button("shotcut_inventory", Vector2(-130.0 - act_gap, -act_offset_y - act_gap + 20.0), 45.0, "KHO\n(Q)", Control.PRESET_BOTTOM_RIGHT)
	
	# Observation and Return buttons
	_add_virtual_button("testkey", Vector2(-130.0 - 2.0*act_gap, -act_offset_y + 35.0), 45.0, "XEM\n(R)", Control.PRESET_BOTTOM_RIGHT)
	_add_virtual_button("return_base", Vector2(-130.0 - 2.0*act_gap, -act_offset_y - act_gap + 20.0), 45.0, "VỀ\n(T)", Control.PRESET_BOTTOM_RIGHT)

func _add_virtual_button(action_name: String, offset: Vector2, radius: float, label_text: String, anchor_preset: int):
	# Generate textures dynamically
	var tex_normal = _generate_circle_texture(radius, Color(0.2, 0.2, 0.2, 0.5), Color(0.8, 0.8, 0.8, 0.8))
	var tex_pressed = _generate_circle_texture(radius, Color(0.8, 0.5, 0.2, 0.7), Color(1.0, 0.9, 0.5, 1.0))
	
	# Create TouchScreenButton
	var tsb = TouchScreenButton.new()
	tsb.action = action_name
	tsb.texture_normal = tex_normal
	tsb.texture_pressed = tex_pressed
	
	# Center the button at the offset position (since position is top-left of the texture)
	tsb.position = offset - Vector2(radius, radius)
	
	# Create a helper wrapper node to anchor the button correctly
	var anchor_node = Control.new()
	anchor_node.set_anchors_and_offsets_preset(anchor_preset)
	add_child(anchor_node)
	anchor_node.add_child(tsb)
	
	# Create Label to show the button text
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	
	# Set label anchors to cover the entire button
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Configure font size
	var font_size = int(radius * 0.35)
	if radius > 60:
		font_size = int(radius * 0.3)
	label.add_theme_font_size_override("font_size", font_size)
	
	tsb.add_child(label)

func _generate_circle_texture(radius: float, fill_color: Color, border_color: Color) -> ImageTexture:
	var size = int(radius * 2.0)
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = radius
	var r_sq = radius * radius
	var border_inner_r_sq = (radius - 2.5) * (radius - 2.5)
	
	for x in range(size):
		for y in range(size):
			var dx = x - center + 0.5
			var dy = y - center + 0.5
			var dist_sq = dx*dx + dy*dy
			
			if dist_sq <= r_sq:
				if dist_sq >= border_inner_r_sq:
					img.set_pixel(x, y, border_color)
				else:
					img.set_pixel(x, y, fill_color)
					
	return ImageTexture.create_from_image(img)
