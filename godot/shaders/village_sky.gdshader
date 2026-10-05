// M3 — bầu trời làng quê (docs/ART_DIRECTION.md §2–§3, thông số trong docs/art_look.json).
// Dải màu chân trời → đỉnh trời, mây tích fBm chiếu lên vòm (xz / (y + 0.25), giống blender/scripts/lighting.py),
// đĩa mặt trời + quầng, ban đêm có trăng tròn và sao. Điều khiển bởi godot/world/day_night.gd.
shader_type sky;

uniform vec3 sky_top : source_color = vec3(0.31, 0.53, 0.78);
uniform vec3 sky_horizon : source_color = vec3(0.75, 0.84, 0.90);
uniform vec3 ground_color : source_color = vec3(0.12, 0.14, 0.09);
uniform vec3 cloud_color : source_color = vec3(0.96, 0.95, 0.92);
uniform float clouds = 0.5;
uniform float night = 0.0;
uniform vec3 moon_dir = vec3(0.47, 0.62, 0.62);
uniform float energy = 1.0;
uniform vec3 mountain_color : source_color = vec3(0.37, 0.48, 0.57);
uniform float mountain_light = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col;
	if (h < 0.0) {
		col = mix(sky_horizon * 0.5, ground_color, smoothstep(0.0, 0.3, -h));
	} else {
		// ~4° trên chân trời đã pha nửa xanh, ~14° là xanh đỉnh trời (khớp dải màu Blender)
		vec3 mid = mix(sky_horizon, sky_top, 0.5);
		col = mix(sky_horizon, mid, smoothstep(0.0, 0.07, h));
		col = mix(col, sky_top, smoothstep(0.07, 0.24, h));
		vec2 uv = d.xz / (h + 0.25) * 1.1 + vec2(TIME * 0.004, 0.0);
		float c = smoothstep(0.52, 0.72, fbm(uv * 2.0)) * clouds;
		col = mix(col, cloud_color, c);
		// dãy núi xa phía Bắc (MAP_BIBLE L14): đường sống núi = nhiễu theo phương vị, cao ~2–6°, mờ sương
		float az = atan(d.x, -d.z);
		float north = smoothstep(0.1, 0.5, -d.z);
		float ridge = (fbm(vec2(az * 2.4, 3.7)) * 0.08 - 0.005) * north;
		if (h < ridge) {
			col = mix(sky_horizon, mountain_color, 0.55) * mountain_light;
			c = 0.0;
		}
		float star = step(0.9975, hash(floor(d.xz / (h + 0.05) * 300.0))) * night * (1.0 - c);
		col += vec3(star) * 1.2;
		float md = dot(d, normalize(moon_dir));
		col += vec3(0.91, 0.93, 1.0) * smoothstep(cos(radians(1.6)), cos(radians(1.3)), md) * 4.0 * night;
	}
	if (LIGHT0_ENABLED) {
		float sd = dot(d, LIGHT0_DIRECTION);
		col += LIGHT0_COLOR * LIGHT0_ENERGY
				* (smoothstep(cos(radians(1.2)), cos(radians(0.9)), sd) * 8.0 + pow(max(sd, 0.0), 64.0) * 0.4);
	}
	COLOR = col * energy;
}
