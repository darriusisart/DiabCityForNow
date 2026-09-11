shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 5.0) = 1.5;
uniform float depth_threshold : hint_range(0.0001, 0.1, 0.0001) = 0.005;
uniform float slope_bias : hint_range(0.0, 20.0) = 4.0; // how much to discount gradual angled surfaces

// Converts nonlinear depth buffer value -> linear view-space depth
float get_linear_depth(vec2 uv, mat4 inv_projection_matrix) {
	float depth = texture(DEPTH_TEXTURE, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void fragment() {
	vec4 scene_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 pixel_size = outline_width / VIEWPORT_SIZE;

	float depth_center = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float depth_left  = get_linear_depth(SCREEN_UV + vec2(-pixel_size.x, 0.0), INV_PROJECTION_MATRIX);
	float depth_right = get_linear_depth(SCREEN_UV + vec2( pixel_size.x, 0.0), INV_PROJECTION_MATRIX);
	float depth_up    = get_linear_depth(SCREEN_UV + vec2(0.0, -pixel_size.y), INV_PROJECTION_MATRIX);
	float depth_down  = get_linear_depth(SCREEN_UV + vec2(0.0,  pixel_size.y), INV_PROJECTION_MATRIX);

	// Sum of neighbor depth differences relative to the center pixel.
	float edge = 0.0;
	edge += abs(depth_center - depth_left);
	edge += abs(depth_center - depth_right);
	edge += abs(depth_center - depth_up);
	edge += abs(depth_center - depth_down);

	// A surface angled away from the camera (a receding floor, a curved
	// silhouette) has a real, gradual depth change per pixel even though
	// it's not an edge. fwidth() estimates that expected local slope so
	// we can subtract it out and keep only genuine discontinuities.
	float slope = fwidth(depth_center) * slope_bias;
	edge = max(edge - slope, 0.0);
	edge /= max(depth_center, 0.001);

	// Smoothstep instead of a hard if/else so pixels near the threshold
	// blend between scene and outline color, softening the jagged/
	// pixelated look a binary cutoff produces on curves and diagonals.
	float outline_amount = smoothstep(depth_threshold * 0.5, depth_threshold * 1.5, edge);

	ALBEDO = mix(scene_color.rgb, outline_color.rgb, outline_amount);
	ALPHA = outline_amount * outline_color.a;
}
