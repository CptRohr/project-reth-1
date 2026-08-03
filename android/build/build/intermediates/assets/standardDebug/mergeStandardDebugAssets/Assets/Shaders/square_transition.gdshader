// Persona 5 square transition
shader_type canvas_item;
render_mode unshaded;

uniform float t = 0.5; // value between 0 and 1 (animation start and end)
uniform vec4 mask_color : source_color = vec4(0.0, 0.0, 0.5, 1.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec2 translate = vec2(-0.25, -0.25);
uniform float extra_size = 1.0;

// returns 1 if it's inside the square, otherwise returns 0
float square(vec2 uv, float width)
{
    return step(max(abs(uv.x), abs(uv.y)), width);
}

vec2 rotate(vec2 uv, float angle)
{
	return uv * mat2(vec2(sin(angle), -cos(angle)), vec2(cos(angle), sin(angle)));
}

void fragment() {
	// convert from 0..1 to -1..1
	vec2 uv = UV * 2.0 - 1.0;
	
	// fix aspect ratio
	uv.y *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	
	// translate
	uv += translate;

	// rotate UVs	
	uv = rotate(uv, PI * 0.25);

	// "draw" square
    float sqr = square(uv, (1.0 + extra_size) * (1.0 - t));
	COLOR = mix(mask_color, background_color, sqr);
}
