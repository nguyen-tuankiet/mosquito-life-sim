// M3 — gió lay cây cỏ (tre, lúa, cỏ, sậy, bụi). Thay material gốc của asset thực vật trong
// godot/world/foliage_loader.gd: giữ texture màu + alpha scissor, thêm lắc theo chiều cao (gốc đứng yên).
// MODEL_MATRIX gồm cả transform từng instance của MultiMesh → mỗi khóm lệch pha theo vị trí.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_tex = true;
uniform float alpha_cut = 0.5;
uniform float sway = 0.15;          // biên độ (m) ở ngọn
uniform float sway_height = 3.0;    // chiều cao (m, toạ độ model) đạt biên độ đầy đủ
uniform float wind_speed = 1.2;
uniform vec2 wind_dir = vec2(1.0, 0.35);

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp(VERTEX.y / sway_height, 0.0, 1.0);
	float ph = dot(wp.xz, vec2(0.13, 0.17));
	float w = sin(TIME * wind_speed + ph) * 0.7 + sin(TIME * wind_speed * 2.3 + ph * 1.7) * 0.3;
	vec3 d = normalize(vec3(wind_dir.x, 0.0, wind_dir.y));
	VERTEX += inverse(mat3(MODEL_MATRIX)) * d * (w * sway * h * h);
}

void fragment() {
	vec4 c = use_tex ? texture(albedo_tex, UV) * albedo_color : albedo_color;
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 0.85;
	BACKLIGHT = c.rgb * 0.35;       // lá xuyên sáng khi ngược nắng
}
