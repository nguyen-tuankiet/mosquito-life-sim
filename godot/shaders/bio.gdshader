shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_schlick_ggx;

// Da sinh vật: đặc (không trong suốt, không nhìn xuyên được) nhưng vẫn có cảm giác mờ xuyên sáng
// nhờ lõi sẫm lộ dưới lớp da, viền sáng ấm (fresnel) và ánh sáng xuyên từ phía sau (BACKLIGHT).
uniform vec4 base_col : source_color = vec4(0.80, 0.68, 0.42, 1.0);
uniform vec4 core_col : source_color = vec4(0.28, 0.18, 0.08, 1.0);
uniform vec4 band_col : source_color = vec4(0.36, 0.27, 0.14, 1.0);
uniform vec4 tip_col : source_color = vec4(0.42, 0.27, 0.13, 1.0);
uniform float body_len = 2.4;
uniform float segs = 8.0;
uniform float spec = 0.7;
uniform float rough = 0.3;
uniform sampler2D noise_tex : hint_default_white;
instance uniform float wig_amp = 0.1;
instance uniform float wig_speed = 10.0;
instance uniform float curl = 0.0;
instance uniform float t_off = 0.0;
instance uniform float blood = 0.0;

varying float vs;

void vertex() {
	float s = clamp(VERTEX.z / body_len, 0.0, 1.3);
	vs = VERTEX.z / body_len;
	float w = sin(TIME * wig_speed + t_off - VERTEX.z * 4.0) * wig_amp * s;
	VERTEX.x += w + curl * s * s * body_len * 0.35;
	VERTEX.y += sin(TIME * wig_speed * 0.5 + t_off + VERTEX.z * 2.0) * wig_amp * 0.25 * s;
}

void fragment() {
	vec3 V = normalize(VIEW);
	float ndv = clamp(dot(NORMAL, V), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 2.2);
	float sip = step(1.0, vs);
	float v = UV.y;
	float band = 0.5 + 0.5 * cos(v * segs * 6.28318);
	float groove = smoothstep(0.78, 1.0, band) * step(0.0, v) * (1.0 - sip);
	vec3 n = texture(noise_tex, UV * vec2(5.0, 14.0)).rgb;
	vec3 skin = mix(base_col.rgb, band_col.rgb, groove * 0.75);
	skin *= 0.82 + 0.34 * n.r;
	skin = mix(skin, tip_col.rgb, sip);
	// lõi đục (ruột/khí quản) lộ qua lớp da: đậm ở giữa thân, nhạt dần ra mép
	float core = pow(ndv, 2.2) * (1.0 - sip);
	vec3 col = mix(skin, core_col.rgb, core * 0.65 * (1.0 - groove * 0.5));
	float tr = smoothstep(0.06, 0.0, abs(abs(UV.x - 0.5) - 0.22)) * step(0.0, v) * (1.0 - sip);
	col = mix(col, core_col.rgb * 0.6, tr * 0.4);
	col = mix(col, vec3(0.48, 0.02, 0.05), blood * (1.0 - groove * 0.7) * (1.0 - sip));
	ALBEDO = col;
	ROUGHNESS = mix(rough, 0.55, groove);
	SPECULAR = spec;
	RIM = 0.2;
	RIM_TINT = 0.7;
	BACKLIGHT = vec3(0.38, 0.28, 0.12);
	// viền sáng ấm giả lập ánh sáng tán xạ dưới da
	EMISSION = base_col.rgb * (0.05 * (1.0 - core) + fres * 0.22);
}
