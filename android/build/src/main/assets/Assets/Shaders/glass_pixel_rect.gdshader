shader_type canvas_item;

// --- Pattern ---
uniform float scale : hint_range(4.0, 256.0) = 120.0;  // pixels per full stripe repeat
uniform float gap   : hint_range(1.0, 80.0)  = 4.5;    // gap between thick and thin stripe
uniform float angle : hint_range(0.0, 360.0) = 45.0;   // rotation of stripes in degrees

// --- Colors ---
uniform vec4 glass_tint   : source_color = vec4(0.62, 0.8, 1.0, 0.15); // base glass fill (alpha = transparency)
uniform vec4 stripe_color : source_color = vec4(1.0, 1.0, 1.0, 0.08);  // stripe + border color (alpha = intensity)
uniform vec4 sun_color    : source_color = vec4(1.0, 1.0, 1.0, 0.59);  // highlight color for dashes

// --- Sun dashes (on stripe edge) ---
uniform float dash_cell    : hint_range(1.0, 32.0) = 6.0;  // pixels per hash cell → controls dash length
uniform float dash_density : hint_range(0.0, 1.0)  = 0.75; // 0 = no dashes, 1 = all lit
uniform float dash_size    : hint_range(0.0, 1.0)  = 0.2;  // fraction of stripe width covered by dashes
uniform bool  dashes_enabled = true;

// --- Border ---
uniform bool  border_enabled     = true;
uniform float border_size        : hint_range(0.01, 20.0) = 1.0;  // border thickness in pixels
uniform float border_dash_cell   : hint_range(1.0, 32.0) = 15.0; // same as dash_cell but for border
uniform float border_dash_density: hint_range(0.0, 1.0)  = 0.5;
uniform float border_dash_size   : hint_range(0.0, 1.0)  = 1.0;  // fraction of border that gets dashes (0=none, 1=full border)
uniform bool  border_dashes_enabled = true;

// --- Internals ---
// Simple pseudo-random: returns 0..1 for any float seed
float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

varying vec2 world_pos;  // vertex world position passed to fragment
varying vec2 local_pos;  // local pixel position (used to auto-compute node size)

void vertex() {
	// Transform local vertex to world space so the pattern stays fixed in the scene
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	// VERTEX is in local pixels; UV maps 0→1 across the node, so VERTEX/UV = node size
	local_pos = VERTEX;
}

void fragment() {
	float shape = texture(TEXTURE, UV).a; // sprite shape mask (1.0 for ColorRect)

	// --- Border ---
	// Auto node size: local_pos interpolates as UV * size, so size = local_pos / UV
	vec2 rect_size = local_pos / max(UV, vec2(0.0001));
	// Detect pixels within border_size pixels of the UV edge
	vec2  b         = vec2(border_size) / rect_size;
	float is_border = border_enabled ? float(UV.x < b.x || UV.x > 1.0 - b.x ||
	                                         UV.y < b.y || UV.y > 1.0 - b.y) : 0.0;

	// --- Stripe geometry ---
	float rad   = angle * PI / 180.0;
	float perp  = world_pos.x * cos(rad) - world_pos.y * sin(rad); // perpendicular to stripe dir
	float along = world_pos.x * sin(rad) + world_pos.y * cos(rad); // along stripe dir (used for dashes)
	float t     = mod(floor(perp), scale); // pixel position within one period

	float thick     = scale * 0.2;  // thick stripe width
	float thin      = scale * 0.07; // thin stripe width
	float sub_start = thick + gap;  // where the thin stripe begins

	float main_line = float(t < thick);
	float sub_line  = float(t >= sub_start && t < sub_start + thin);
	float on_stripe = clamp(main_line + sub_line, 0.0, 1.0);

	// --- Sun dashes ---
	// Only on the outer 15% of each stripe (the sun-facing edge)
	float main_edge = main_line * float(t < thick * dash_size);
	float sub_local = (t - sub_start) / max(thin, 0.001);
	float sub_edge  = sub_line * float(sub_local < dash_size);
	float on_edge   = clamp(main_edge + sub_edge, 0.0, 1.0);

	// Hash varies per cell along the stripe — same cell = same width → uniform dash width
	float cell      = floor(along / dash_cell);
	float stripe_id = float(sub_line > 0.5); // different seed for main vs thin stripe
	float rng       = hash(cell * 127.1 + stripe_id * 311.7);
	float sun_mask  = dashes_enabled ? on_edge * float(rng > (1.0 - dash_density)) : 0.0;

	// --- Border dashes ---
	// Separate UV zone: outermost (border_size * border_dash_size) pixels get the dashes
	vec2  bd           = vec2(border_size * border_dash_size) / rect_size;
	float is_dash_zone = float(UV.x < bd.x || UV.x > 1.0 - bd.x ||
	                           UV.y < bd.y || UV.y > 1.0 - bd.y);
	// Use x+y as coordinate so dashes flow consistently along all 4 sides
	float b_coord     = floor(world_pos.x + world_pos.y);
	float b_cell      = floor(b_coord / border_dash_cell);
	float b_rng       = hash(b_cell * 213.7 + 7777.0);
	float border_dash = border_dashes_enabled
		? is_dash_zone * float(b_rng > (1.0 - border_dash_density))
		: 0.0;

	// --- Compose ---
	// Start from glass base, layer stripes, then border on top
	vec3 rgb = glass_tint.rgb;

	rgb = mix(rgb, stripe_color.rgb, on_stripe  * (1.0 - is_border) * stripe_color.a); // stripe fill
	rgb = mix(rgb, sun_color.rgb,    sun_mask   * (1.0 - is_border) * sun_color.a);    // sun dashes on stripe (own alpha)
	rgb = mix(rgb, stripe_color.rgb, is_border * stripe_color.a);                    // border fill
	rgb = mix(rgb, sun_color.rgb,  is_border  * border_dash       * sun_color.a);    // border dash highlights

	float alpha = clamp(
		glass_tint.a
		+ on_stripe  * (1.0 - is_border) * stripe_color.a
		+ is_border  * stripe_color.a,
		0.0, 1.0);

	COLOR = vec4(rgb, alpha * shape);
}
