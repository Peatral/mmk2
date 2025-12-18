shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURFACE_DIST = 0.01;

uniform sampler2D noise_smooth;
uniform sampler2D noise_spikey;
uniform sampler2D color_gradient: source_color;

const int MAX_BUBBLES = 16;
uniform int bubble_count = 3;
uniform vec3 bubble_positions[MAX_BUBBLES];
uniform vec4 bubble_data[MAX_BUBBLES];


vec2 get_spherical_uv(vec3 p) {
	vec3 n = normalize(p);
	float u = atan(n.z, n.x) / (2.0 * PI) + 0.5;
	float v = asin(n.y) / PI + 0.5;
	return vec2(u, v);
}

vec4 smooth_blend(vec4 d1, vec4 d2, float k, float blend_factor, out float h) {
	h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0.0, 1.0);
	float d = mix(d2.w, d1.w, h) + blend_factor * k * h * (1.0 - h);
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
	vec2 current_params = vec2(0.0);

	for (int i = 0; i < bubble_count; i++) {
		vec3 pos = bubble_positions[i];
		float radius = bubble_data[i].x;
		float strength = bubble_data[i].y;
		float shape_blend = bubble_data[i].z;
		float color_blend = bubble_data[i].w;
		vec3 col = texture(color_gradient, vec2(clamp(color_blend, 0.01, 0.99), 0.5)).rgb;
		float d = sd_bubble(p, pos, radius, strength, shape_blend);
		
		vec2 new_params = vec2(shape_blend, color_blend);

		if (i == 0) {
			global_data.rgb = col;
			global_data.w = d;
			current_params = new_params;
		} else {
			vec4 d2 = vec4(col, d);
			
			// Similarity is based on shape_blend (z) and color_blend (w)
			float dist_params = distance(current_params, new_params);
			float similarity = pow(1.0 - clamp(dist_params / 1.414, 0.0, 1.0), 4.0);

			// Adjust k and blend_factor based on similarity.
			// For rejection (similarity 0):
			// k = 0.3: Moderate transition width to avoid "fog" but keep interaction localized.
			// blend_factor = 0.8: Positive value creates a "groove" or indentation, simulating repulsion/pressure.
			
			// For attraction (similarity 1):
			// k = 0.8: Large smooth blend.
			// blend_factor = -1.0: Standard smooth union.
			
			float k = mix(0.5, 0.8, similarity);
			float blend_factor = mix(1.0, -1.0, similarity);

			float h;
			global_data = smooth_blend(global_data, d2, k, blend_factor, h);
			current_params = mix(new_params, current_params, h);
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
