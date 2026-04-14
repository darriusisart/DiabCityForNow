shader_type canvas_item;

// ── Character Color Replacement Shader (Advanced) ──
// Replaces specific base colors in the sprite with player-chosen colors.
// Uses HSV conversion to PRESERVE the original sprite's shading/brightness
// so recolored areas still look natural (not flat).

// Body / Skin
uniform vec4 oldColorBody : source_color = vec4(0.96, 0.8, 0.68, 1.0);
uniform vec4 newColorBody : source_color = vec4(0.96, 0.8, 0.68, 1.0);

// Eyes
uniform vec4 oldColorEyes : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec4 newColorEyes : source_color = vec4(0.2, 0.4, 0.6, 1.0);

// Detail slot 1 (shirt, hair, etc.)
uniform vec4 oldColor1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 newColor1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Detail slot 2 (pants, accessories, etc.)
uniform vec4 oldColor2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 newColor2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// How close a pixel must be to the old color to be replaced (0 = exact, 1 = loose)
uniform float precision : hint_range(0.0, 1.0, 0.01) = 0.15;

// ── RGB ↔ HSV helpers ──
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Recolor a pixel: take the NEW color's hue & saturation,
// but keep the ORIGINAL pixel's brightness (value) offset
// relative to the old base color. This preserves shading.
vec3 recolor_preserve_shading(vec3 original_rgb, vec3 old_rgb, vec3 new_rgb) {
	vec3 old_hsv = rgb2hsv(old_rgb);
	vec3 new_hsv = rgb2hsv(new_rgb);
	vec3 pixel_hsv = rgb2hsv(original_rgb);

	// Brightness difference between this pixel and the base old color
	float value_offset = pixel_hsv.z - old_hsv.z;

	// Use new hue + saturation, adjust value by original shading offset
	vec3 result_hsv = vec3(
		new_hsv.x,                                    // new hue
		new_hsv.y,                                    // new saturation
		clamp(new_hsv.z + value_offset, 0.0, 1.0)    // new value + original shading
	);

	return hsv2rgb(result_hsv);
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 col = tex_color * COLOR;

	// ── Check each color slot (specific → broad) ──
	// Eyes
	float match_eyes = step(distance(col.rgb, oldColorEyes.rgb), precision);
	vec3 recolored_eyes = recolor_preserve_shading(col.rgb, oldColorEyes.rgb, newColorEyes.rgb);
	col.rgb = mix(col.rgb, recolored_eyes, match_eyes);

	// Detail 1
	float match_1 = step(distance(col.rgb, oldColor1.rgb), precision);
	vec3 recolored_1 = recolor_preserve_shading(col.rgb, oldColor1.rgb, newColor1.rgb);
	col.rgb = mix(col.rgb, recolored_1, match_1);

	// Detail 2
	float match_2 = step(distance(col.rgb, oldColor2.rgb), precision);
	vec3 recolored_2 = recolor_preserve_shading(col.rgb, oldColor2.rgb, newColor2.rgb);
	col.rgb = mix(col.rgb, recolored_2, match_2);

	// Body / Skin (checked last so it doesn't override smaller detail regions)
	float match_body = step(distance(col.rgb, oldColorBody.rgb), precision);
	vec3 recolored_body = recolor_preserve_shading(col.rgb, oldColorBody.rgb, newColorBody.rgb);
	col.rgb = mix(col.rgb, recolored_body, match_body);

	COLOR = col;
}
