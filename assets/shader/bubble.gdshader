shader_type spatial;
render_mode unshaded;

uniform sampler2D spikey_noise;
uniform sampler2D smooth_noise;
uniform float shape_blend: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform sampler2D color_gradient: source_color;
uniform float color_blend: hint_range(0.01, 0.99, 0.01) = 0.5;
uniform float radius = 0.5;
uniform float strength = 0.5;
uniform float speed = 0.01;


void vertex() {
	vec2 uv = UV + vec2(0, TIME * speed);
	float smooth_value = textureLod(smooth_noise, uv, 0).r * strength;
	float spikey_value = textureLod(spikey_noise, uv, 0).r * strength;
	VERTEX = NORMAL * (radius + mix(smooth_value, spikey_value, shape_blend) * radius);
}

void fragment() {
	ALBEDO = textureLod(color_gradient, vec2(color_blend, 0.5), 0).rgb;
}
