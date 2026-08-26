shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size : hint_range(0.0, 70.0) = 3.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_size;

	float outline_alpha = 0.0;

	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a);

	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)).a);

	vec4 outline = outline_color;
	outline.a *= outline_alpha * (1.0 - tex.a);

	COLOR = mix(outline, tex, tex.a);
}