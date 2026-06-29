// item_box_outline.gdshader 복제본 — 경험치 보너스 아이콘 전용.
// 차이점: 마지막에 MODULATE를 곱해 노드 modulate(틴트·페이드 알파)를 반영한다.
// (원본은 COLOR를 직접 출력해 modulate가 먹지 않음 → 아이콘 페이드 연출용으로 분리)
shader_type canvas_item;
render_mode unshaded;

uniform bool Smooth = true;
uniform float width : hint_range(0.0, 64) = 1.0;
uniform vec4 outline_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int pixel_size : hint_range(1, 10) = 4;
uniform float width_speed :hint_range(0.1, 10) = 1;

// vertex의 COLOR = 노드 modulate(× self_modulate). MODULATE 빌트인이 없는
// 렌더러(Compatibility/OpenGL)에서도 동작하도록 varying으로 전달한다.
varying vec4 modulate_color;

void vertex()
{
    modulate_color = COLOR;
}

void fragment()
{
    float _width = width; // 펄싱(늘었다 줄었다) 제거 — 외곽선 폭 고정
    vec2 unit = (1.0/float(pixel_size) ) / vec2(textureSize(TEXTURE, 0));
    vec4 pixel_color = texture(TEXTURE, UV);
    if (pixel_color.a == 0.0) {
        pixel_color = outline_color;
        pixel_color.a = 0.0;
        for (float x = -ceil(_width); x <= ceil(_width); x++) {
            for (float y = -ceil(_width); y <= ceil(_width); y++) {
                if (texture(TEXTURE, UV + vec2(x*unit.x, y*unit.y)).a == 0.0 || (x==0.0 && y==0.0)) {
                    continue;
                }
                if (Smooth) {
                    pixel_color.a += outline_color.a / (pow(x,2)+pow(y,2)) * (1.0-pow(2.0, -_width));
                    if (pixel_color.a > 1.0) {
                        pixel_color.a = 1.0;
                    }
                } else {
                    pixel_color.a = outline_color.a;
                }
            }
        }
    }
    COLOR = pixel_color * modulate_color; // 노드 modulate(틴트·페이드) 반영
}
