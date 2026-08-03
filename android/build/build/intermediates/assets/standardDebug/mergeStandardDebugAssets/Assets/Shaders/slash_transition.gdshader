// Persona 5 slash transition
shader_type canvas_item;
render_mode unshaded;

uniform float t = 0.5; // value between 0 and 1 (animation start and end)
uniform float power = 10.0; 
uniform vec4 mask_color : source_color = vec4(0.0, 0.0, 0.5, 1.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec2 normal = vec2(1.0, 1.0);
uniform float offset = -0.5;

void fragment() {
    vec2 p = UV;

    float dist = abs(dot(normalize(normal), p) + offset);
	
	float thickness = pow(t, power);

    float line = dist <= thickness ? 1.0 : 0.0;

    COLOR = mix(background_color, mask_color, line);
}
