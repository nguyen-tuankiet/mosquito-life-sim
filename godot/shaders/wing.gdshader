shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
// Cánh côn trùng: màng trong suốt có gân và ánh cầu vồng nhẹ.
uniform vec4 tint : source_color = vec4(0.85, 0.92, 1.0, 1.0);
void fragment() {
	vec2 uv = UV;
	float vein = 0.0;
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		float a = uv.y - (0.5 + (fi - 2.0) * 0.12) * (0.6 + uv.x * 0.4);
		vein = max(vein, smoothstep(0.012, 0.0, abs(a)));
	}
	vein = max(vein, smoothstep(0.02, 0.0, uv.y - 0.06));
	float edge = smoothstep(0.0, 0.1, uv.x) * smoothstep(0.0, 0.18, 1.0 - uv.x);
	float irid = 0.5 + 0.5 * sin(uv.x * 14.0 + uv.y * 9.0 + TIME * 0.5);
	ALBEDO = tint.rgb * (0.9 + 0.1 * irid) * (1.0 - vein * 0.6);
	ALPHA = clamp(0.16 + vein * 0.7, 0.0, 0.9) * edge;
	ROUGHNESS = 0.1;
	SPECULAR = 0.9;
	EMISSION = vec3(0.25, 0.3, 0.4) * irid * 0.15 * edge;
}
