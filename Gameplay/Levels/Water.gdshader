shader_type canvas_item;

uniform sampler2D refraction_map;

uniform vec2 refraction_stretch = vec2(1.0, 1.0);
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.02;

uniform vec4 water_tint : source_color = vec4(0.2, 0.6, 1.0, 0.1);
uniform float speed : hint_range(0.0, 1.0) = 0.1;

uniform vec4 water_highlight = vec4(1.0, 1.0, 1.0, 0.3);  // 하이라이트 색상
uniform float highlight_width : hint_range(0.0, 0.3) = 0.02;  // 하이라이트 두께

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

varying vec2 globalposition;

void vertex(){
	globalposition = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment()
{
	vec2 uv = globalposition / 512.0;

	// Refraction offset 계산
	vec2 refraction_offset = texture(
		refraction_map,
		vec2(
			mod(uv.x * refraction_stretch.x + TIME * speed, 1.0),
			mod(uv.y * refraction_stretch.y + TIME * speed, 1.0))).xy;

	// 0.5로 보정하여 움직이는 반사 오프셋 설정
	refraction_offset -= 0.5;

	// 화면 텍스처와 굴절 효과 적용
	vec4 refraction = texture(SCREEN_TEXTURE, SCREEN_UV - refraction_offset * refraction_strength);

	// 외곽선(하이라이트) 적용을 위한 기본 색상 설정
	vec4 color = vec4(1.0);

	// 수직 외곽선을 위한 거리 계산 (상하)
	float distance_to_edge_y = min(UV.y, 1.0 - UV.y);  // 상하 외곽에서의 거리 계산

	// 외곽선 적용 (상하 외곽선 부분)
	if (distance_to_edge_y < highlight_width) {
		color.rgb = mix(refraction.rgb, water_highlight.rgb, water_highlight.a);
	} else {
		// 일반적인 색상 적용 (내부)
		color.rgb = mix(refraction.rgb, water_tint.rgb, water_tint.a);
	}

	// 최종 색상 출력
	COLOR = color;
}
