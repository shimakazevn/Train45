shader_type canvas_item;

uniform float final_uv_x;  // GDScript에서 전달받는 최종 UV.x 값

void fragment() {
	// GDScript에서 전달받은 최종 UV.x 값으로 텍스처 이동
	COLOR = texture(TEXTURE, vec2(UV.x + final_uv_x, UV.y));
}
