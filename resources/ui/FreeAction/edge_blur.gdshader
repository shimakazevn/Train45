shader_type canvas_item;

// 가장자리 블러 전용. BlurRect.png 같은 마스크 텍스처의 알파로 블러 영역을 제한한다.
// 가장자리(불투명)에만 블러가 보이고, 가운데(투명)는 구멍으로 남는다.

uniform float lod: hint_range(0.0, 5.0) = 1.1;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float mix_percentage: hint_range(0.0, 1.0) = 0.2;

void fragment() {
	float mask = texture(TEXTURE, UV).a; // 마스크 텍스처 알파(가장자리=1, 가운데=0)
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	color = mix(color, vec4(0, 0, 0, 1), mix_percentage);
	color.a *= mask; // 마스크 알파만큼만 블러를 그려서 가운데 구멍을 유지
	COLOR = color;
}
