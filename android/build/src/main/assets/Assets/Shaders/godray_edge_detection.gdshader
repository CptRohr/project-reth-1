shader_type canvas_item;
render_mode unshaded;

const lowp float LOD = 8.0; // Level of detail used in the screen texture.
const lowp vec2 DEADZONE = vec2(0.0, -1.0); // Vertical lines can be broken, this constant is used as a dot to prevent this effect.

uniform lowp float output_multiplier: hint_range(0.0, 1.0, 0.1) = 1.0; // Multiplies the entire output. Can be used to manually tone the rays.
uniform lowp vec2 ray_direction = vec2(0.5, -1.0); // Vector direction of the lines.
group_uniforms RayParameters;
uniform lowp vec3 ray_color: source_color = vec3(1.0, 1.0, 0.8); // Color tint of the rays.
uniform lowp float ray_length = 0.15; // Length of lines in SCREEN_UV.
uniform lowp int ray_samples: hint_range(8, 128, 8) = 64; // Amount of steps of marching used in the main loop to search alpha and edges (higher values can impact performance).
uniform lowp float edge_sensitivity = 8.0; // Multiplier of ray intensity when the sampled pixel is in the edge of alpha and opaque.
uniform lowp float color_edge_multiplier: hint_range(0.0, 1.0, 0.1) = 0.2; // Changes the color difference impact on the godrays
uniform lowp float alpha_edge_multiplier: hint_range(0.0, 1.0, 0.1) = 1.0; // Changes the alpha difference impact on the godrays.
uniform lowp float intensity = 1.0; // Color intensity of the rays.

uniform sampler2D SCREEN_TEXTURE: repeat_enable, filter_linear_mipmap, hint_screen_texture;

bool out_of_bounds(lowp vec2 uv) {
	return (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0);
}

void fragment() {
	lowp vec4 base_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, LOD);
	
	lowp vec2 normalized_ray = normalize(ray_direction);
	lowp vec2 sample_offset = normalized_ray * ray_length / float(ray_samples);
	lowp float edge_sample_offset = length(sample_offset) * 0.5;
	
	lowp vec3 accumulated_ray = vec3(0.0);
	lowp float accumulated_alpha = 0.0;
	
	for(int i = 0; i < ray_samples; i++) {
		lowp float sample_progress = float(i) / float(ray_samples);
		lowp vec2 sample_uv = SCREEN_UV + sample_offset * float(i);
		
		if(out_of_bounds(sample_uv)) { continue; }
		
		lowp vec4 sample_color = textureLod(SCREEN_TEXTURE, sample_uv, LOD);
		
		// Sobel-like edge detection: forward/backward difference
		lowp vec4 sample_forward = textureLod(SCREEN_TEXTURE, sample_uv + normalized_ray * edge_sample_offset, LOD);
		lowp vec4 sample_backward = textureLod(SCREEN_TEXTURE, sample_uv - normalized_ray * edge_sample_offset, LOD);
		
		lowp float alpha_edge = abs(sample_forward.a - sample_backward.a) * alpha_edge_multiplier; // Diference in alpha for alpha edge detection.
		lowp float color_edge = length(sample_forward.rgb - sample_backward.rgb) * color_edge_multiplier; // Difference in color for color edge detection.
		lowp float edge_strength = clamp(max(alpha_edge, color_edge) * edge_sensitivity, 0.0, 1.0); // Highest edge value is used as part of the contribution.
		
		lowp float falloff = 1.0 - sample_progress;
		lowp float contribution = edge_strength * falloff;
		
		accumulated_ray += sample_color.rgb * contribution;
		accumulated_alpha += contribution;
	}
	
	// lowp float direction_dot = 1.0; <- Usable if needed to have vertical lines.
	lowp float direction_dot = clamp(1.0 - dot(normalized_ray, DEADZONE), 0.0, 1.0);
	
	accumulated_ray /= float(ray_samples);
	accumulated_ray *= intensity * direction_dot * output_multiplier;
	accumulated_alpha /= float(ray_samples);
	accumulated_alpha *= intensity * direction_dot * output_multiplier;
	accumulated_ray += vec3(1.0 - base_color.a);
	accumulated_ray *= ray_color;
	
	COLOR = vec4(accumulated_ray + base_color.rgb, base_color.a + accumulated_alpha);
}