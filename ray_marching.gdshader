shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURFACE_DIST = 0.01;

uniform sampler2D noise_smooth;
uniform sampler2D noise_spikey;
uniform sampler2D color_gradient: source_color;

uniform int bubble_count = 3;
uniform vec3 bubble_positions[3];
uniform vec4 bubble_data[3];


vec2 get_spherical_uv(vec3 p) {
	vec3 n = normalize(p);
	float u = atan(n.z, n.x) / (2.0 * PI) + 0.5;
	float v = asin(n.y) / PI + 0.5;
	return vec2(u, v);
}

vec4 smooth_union(vec4 d1, vec4 d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0.0, 1.0);
	float d = mix(d2.w, d1.w, h) - k * h * (1.0 - h);
	vec3 col = mix(d2.rgb, d1.rgb, h);
	return vec4(col, d);
}

float sd_sphere(vec3 p, vec3 sp, float r) {
	return length(sp - p) - r;
}

float sd_bubble(vec3 p, vec3 sp, float r, float strength, float noise_mix) {
	float d_sphere = sd_sphere(p, sp, r);
	vec2 derived_uv = get_spherical_uv(p - sp);
	vec2 moved_uv = derived_uv + vec2(0, TIME * 0.03);
	float smooth_noise = texture(noise_smooth, moved_uv).r;
	float spikey_noise = texture(noise_spikey, moved_uv).r;
	float noise = mix(smooth_noise, spikey_noise, noise_mix);
	return d_sphere - (noise - 0.5) * strength * r;
}

vec4 get_scene(vec3 p) {
	vec4 global_data = vec4(texture(color_gradient, vec2(0.5, 0.5)).rgb, MAX_DIST);
	for (int i = 0; i < bubble_count; i++) {
		vec3 pos = bubble_positions[i];
		float radius = bubble_data[i].x;
		float strength = bubble_data[i].y;
		float shape_blend = bubble_data[i].z;
		float color_blend = bubble_data[i].w;
		vec3 col = texture(color_gradient, vec2(clamp(color_blend, 0.01, 0.99), 0.5)).rgb;
		float d = sd_bubble(p, pos, radius, strength, shape_blend);
		if (i == 0) {
			global_data.rgb = col;
			global_data.w = d;
		} else {
			global_data = smooth_union(global_data, vec4(col, d), 0.5);
		}
	}
	return global_data;
}

vec3 get_normal(vec3 p) {
	float d = get_scene(p).w;
	vec2 e = vec2(0.01, 0.0);
	vec3 n = d - vec3(
		get_scene(p-e.xyy).w,
		get_scene(p-e.yxy).w,
		get_scene(p-e.yyx).w
	);
	return normalize(n);
}

vec4 ray_march(vec3 ro, vec3 rd) {
	float d = 0.0;
	vec3 col = vec3(0);
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 p = ro + rd * d;
		vec4 data = get_scene(p);
		float ds = data.w;
		d += ds;
		if (d > MAX_DIST || ds < SURFACE_DIST) {
			col = data.rgb;
			break;
		}
	}
	return vec4(col, d);
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec3 ws_pixel_pos = ((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(ws_pixel_pos - ro);
	
	vec4 data = ray_march(ro, rd);
	float d = data.w;
	ALPHA = step(d, min(linear_depth, MAX_DIST));
	
	ALBEDO = data.rgb;
}
