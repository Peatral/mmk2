shader_type particles;
render_mode disable_velocity;

uniform sampler2D data_texture : source_color;

// --- Camera Intrinsics ---
// You MUST set these to match your camera and depth mode.
// For Azure Kinect NFOV_Unbinned (640x576), typical values are:
// texture_size = ivec2(640, 576)
// camera_fx = 504.6
// camera_fy = 504.5
// min_depth = 50.0
// max_depth = 1000.0
// --------------------------

uniform ivec2 texture_size = ivec2(640, 576);

// Focal length (in pixels)
uniform vec2 focal_length = vec2(504.6, 504.5);

uniform float min_depth : hint_range(0, 10) = 0.05;
uniform float max_depth : hint_range(0, 10) = 1.0;

void process() {
    int idx = int(INDEX);

    int total_pixels = texture_size.x * texture_size.y;

    if (idx >= total_pixels) {
        ACTIVE = false;
    } else {
        ivec2 pixel_coord = ivec2(idx % texture_size.x, idx / texture_size.x);
        vec2 uv = (vec2(pixel_coord) + 0.5) / vec2(texture_size);
        float brightness = texture(data_texture, uv).r;
        COLOR.rgba = vec4(vec3(brightness), 1.0);
        if (brightness > 0.0) {
            float t = 1.0 - brightness;
            float depth = mix(min_depth, max_depth, t);

            vec2 center = vec2(texture_size) / 2.0;

            vec3 pos_camera;
            pos_camera.xy = (vec2(pixel_coord) - center) * depth / focal_length;
            pos_camera.z = depth;

            // Convert from Kinect's coordinate system to Godot's
            // Kinect: +X Right, +Y Down,  +Z Forward
            // Godot:  +X Right, +Y Up,    +Z Back

            CUSTOM.x = mix(0.001, 10, t);
			TRANSFORM[3].xyz = vec3(pos_camera.x, -pos_camera.y, -pos_camera.z);
		} else {
			COLOR.a = 0.0;
			TRANSFORM[3].xyz = vec3(0.0);
		}
    }
}