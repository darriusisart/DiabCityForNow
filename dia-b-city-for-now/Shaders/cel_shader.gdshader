shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform vec4 shadow_color : source_color = vec4(0.35, 0.4, 0.5, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
	ROUGHNESS = 0.8;
}

void light() {
	float light_amount = max(dot(NORMAL, LIGHT), 0.0);

	float cel = step(shadow_threshold, light_amount);

	vec3 cel_color = mix(shadow_color.rgb, vec3(1.0), cel);

	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * cel_color;
}