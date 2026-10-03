// Mặt nước của map làng quê (M2): ao tĩnh, kênh chảy chậm, ruộng nông, vũng mưa.
// Gợn sóng bằng hàm sin → không cần texture; flow khác 0 cho kênh (nước trôi theo hướng chảy).
// Màu theo docs/ART_DIRECTION.md §3 (ao #4E7680, nước tù #5B6B48).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.306, 0.463, 0.502, 0.85);
uniform vec2 flow = vec2(0.0, 0.0);
uniform float wave_scale = 0.35;
uniform float wave_strength = 0.18;
uniform float roughness = 0.06;

varying vec3 world_pos;

float wave(vec2 p, float t) {
	return sin(p.x * 1.7 + t * 0.9) * cos(p.y * 1.3 - t * 0.7) + 0.5 * sin(p.x * 3.1 - p.y * 2.3 + t * 1.3);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * wave_scale - flow * TIME;
	float e = 0.05;
	float dx = (wave(p + vec2(e, 0.0), TIME) - wave(p - vec2(e, 0.0), TIME)) / (2.0 * e);
	float dz = (wave(p + vec2(0.0, e), TIME) - wave(p - vec2(0.0, e), TIME)) / (2.0 * e);
	vec3 bend = (VIEW_MATRIX * vec4(-dx, 0.0, -dz, 0.0)).xyz * wave_strength;
	NORMAL = normalize(NORMAL + bend);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(water_color.rgb, vec3(0.75, 0.85, 0.92), fres * 0.5);
	ALPHA = mix(water_color.a, 1.0, fres);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
