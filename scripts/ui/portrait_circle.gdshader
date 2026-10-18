shader_type canvas_item;
// Masks a texture to a circle (used for atlas portraits).
uniform float radius : hint_range(0.1, 0.5) = 0.45;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float edge = fwidth(d);
	COLOR.a *= 1.0 - smoothstep(radius - edge, radius, d);
}
