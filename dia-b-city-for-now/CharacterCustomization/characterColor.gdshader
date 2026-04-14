shader_type canvas_item;
// Character color replacement: set oldColor* in the material to the original sprite
// pixel colors you want to replace; newColor* are the chosen customization colors.
// Adjust precision (0.0–1.0) for stricter/looser color matching.

uniform vec4 newColorBody : source_color;
uniform vec4 oldColorBody : source_color;
uniform vec4 newColorEyes : source_color;
uniform vec4 oldColorEyes : source_color;
uniform vec4 newColor1 : source_color;
uniform vec4 oldColor1 : source_color;
uniform vec4 newColor2 : source_color;
uniform vec4 oldColor2 : source_color;

uniform float precision : hint_range(0.0, 1.0, 0.1);

uniform float onlyPickMainColor : hint_range(0.0, 1.0, 0.1);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 col = tex_color * COLOR;

	// Color replacement: if pixel matches oldColor within precision, use newColor (preserve alpha)
	// Order: check eyes and details first, then body (so specific regions override)
	float match_eyes = step(distance(col.rgb, oldColorEyes.rgb), precision);
	col = mix(col, vec4(newColorEyes.rgb, col.a), match_eyes);

	float match_1 = step(distance(col.rgb, oldColor1.rgb), precision);
	col = mix(col, vec4(newColor1.rgb, col.a), match_1);

	float match_2 = step(distance(col.rgb, oldColor2.rgb), precision);
	col = mix(col, vec4(newColor2.rgb, col.a), match_2);

	float match_body = step(distance(col.rgb, oldColorBody.rgb), precision);
	col = mix(col, vec4(newColorBody.rgb, col.a), match_body);

	COLOR = col;
}
