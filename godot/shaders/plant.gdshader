shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
// Cây thủy sinh dạng dải lá (Vallisneria): đung đưa theo dòng nước, mờ xuyên sáng.
uniform vec4 base_col : source_color = vec4(0.08, 0.28, 0.12, 1.0);
uniform vec4 tip_col : source_color = vec4(0.45, 0.72, 0.28, 1.0);
uniform float sway = 0.22;
void vertex() {
	float h = clamp(VERTEX.y, 0.0, 1.0);
	float ph = MODEL_MATRIX[3].x * 1.7 + MODEL_MATRIX[3].z * 1.1;
	VERTEX.x += sin(TIME * 1.15 + ph) * h * h * sway + sin(TIME * 2.3 + ph * 1.7) * h * h * 0.04;
	VERTEX.z += cos(TIME * 0.9 + ph * 1.3) * h * h * sway * 0.6;
}
void fragment() {
	float h = UV.y;
	vec3 col = mix(base_col.rgb, tip_col.rgb, pow(h, 1.3));
	float vein = smoothstep(0.03, 0.0, abs(UV.x - 0.5));
	col *= 1.0 - vein * 0.25;
	ALBEDO = col;
	ROUGHNESS = 0.55;
	SPECULAR = 0.4;
	BACKLIGHT = tip_col.rgb * 0.5;
	ALPHA = 1.0 - smoothstep(0.92, 1.0, h) * 0.6;
}
