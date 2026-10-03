shader_type spatial;
render_mode cull_disabled, unshaded;
// Lông tơ (setae): mảnh, sẫm, hơi trong; uốn theo thân bằng cùng công thức với bio.gdshader.
uniform vec4 col : source_color = vec4(0.16, 0.12, 0.08, 0.75);
uniform float body_len = 2.4;
instance uniform float wig_amp = 0.1;
instance uniform float wig_speed = 10.0;
instance uniform float curl = 0.0;
instance uniform float t_off = 0.0;
void vertex() {
	float s = clamp(VERTEX.z / body_len, 0.0, 1.3);
	float w = sin(TIME * wig_speed + t_off - VERTEX.z * 4.0) * wig_amp * s;
	VERTEX.x += w + curl * s * s * body_len * 0.35;
	VERTEX.y += sin(TIME * wig_speed * 0.5 + t_off + VERTEX.z * 2.0) * wig_amp * 0.25 * s;
}
void fragment() {
	ALBEDO = col.rgb;
	ALPHA = col.a * (1.0 - UV.y * 0.7);
}
