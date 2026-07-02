shader_type canvas_item;

uniform vec4 clr : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int type : hint_range(1, 2) = 2;
uniform float thickness = 1.0;

const vec2[8] DIRECTIONS = {
	vec2(1.0, 0.0),
	vec2(0.0, 1.0),
	vec2(-1.0, 0.0),
	vec2(0.0, -1.0),
	vec2(1.0, 1.0),
	vec2(-1.0, 1.0),
	vec2(-1.0, -1.0),
	vec2(1.0, -1.0)
};

float gtz(float input) { return max(0, sign(input)); }
// returns 1 if input > 0, else 0

// [VI] Inline trực tiếp trong fragment(): KHÔNG truyền TEXTURE (built-in) vào hàm phụ,
// vì trình biên dịch shader Compatibility/mobile báo lỗi
// "!actions.custom_samplers.has(...)" khi sampler built-in được truyền qua tham số hàm.
void fragment() {
	float result = 0.0;
	for (int i = 0; i < 4 * type; i++) {
		result += texture(TEXTURE, UV + DIRECTIONS[i] * TEXTURE_PIXEL_SIZE * thickness).a;
	}
	float outline = gtz(result);
	COLOR = mix(COLOR, clr, outline - gtz(COLOR.a));
}
