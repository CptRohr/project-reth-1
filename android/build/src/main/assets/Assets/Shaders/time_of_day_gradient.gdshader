shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.72, 0.89, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.98, 0.97, 0.90, 1.0);

void fragment() {
	vec2 uv = UV;
	vec4 gradient_color = mix(top_color, bottom_color, uv.y);
	COLOR = gradient_color;
}
