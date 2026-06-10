shader_type canvas_item;

/* HSV wheel: H = angle, S = radius, V = 1.0 (center is white).
   Works on ColorRect/TextureRect/Polygon2D with 0..1 UVs. */

uniform vec2  center_uv = vec2(0.5, 0.5); // center in UV coords
uniform float radius_uv = 0.48;           // outer radius in UV units (0.5 ≈ full square)
uniform float inner_uv  = 0.0;            // inner radius (0 -> solid disk, >0 -> ring)
uniform float feather   = 0.002;          // soft edge for outer/inner boundaries
uniform float value     = 1.0;            // V component of HSV
uniform bool  show_cursor = true;         // whether to draw cursor indicator
uniform vec2  cursor_uv = vec2(0.5, 0.5); // cursor position in UV coords
uniform vec4  border_color : source_color = vec4(0.1, 0.1, 0.1, 1.0); // border color
uniform float border_width = 0.01;       // border width in UV units

// Correct: uses S (c.y) and V (c.z)
vec3 hsv2rgb(vec3 c) {
    // c = vec3(h, s, v), h in [0,1)
    vec3 k = vec3(1.0, 2.0/3.0, 1.0/3.0);
    vec3 p = abs(fract(c.x + k) * 6.0 - 3.0);
    vec3 rgb = clamp(p - 1.0, 0.0, 1.0);
    // mix toward white when saturation goes to 0
    return c.z * mix(vec3(1.0), rgb, c.y);
}


void fragment() {
    vec2 d = UV - center_uv;        // centered UV (assumes square rect; if not, scale x by aspect)
    float r = length(d);            // distance from center in UV units

    // Compute alpha with soft inner/outer edges
    float a_outer = smoothstep(radius_uv, radius_uv - max(feather, 1e-6), r);
    float a_inner = (inner_uv <= 0.0) ? 1.0 : (1.0 - smoothstep(inner_uv, inner_uv + max(feather, 1e-6), r));
    float alpha   = a_outer * a_inner;
    if (alpha <= 0.0) discard;

    // HSV: hue from angle, saturation from radius, value fixed at 1.0
    float hue = fract(atan(d.y, d.x) / (2.0 * PI));
    float sat = clamp((r - inner_uv) / max(radius_uv - inner_uv, 1e-6), 0.0, 1.0);
    vec3  rgb = hsv2rgb(vec3(hue, sat, value));

    // Draw border at the outer edge
    float border_start = radius_uv - border_width;
    if (r >= border_start && r <= radius_uv) {
        float border_alpha = smoothstep(border_start - feather, border_start, r) * 
                            smoothstep(radius_uv, radius_uv - feather, r);
        rgb = mix(rgb, border_color.rgb, border_alpha * border_color.a);
    }

    // Draw cursor indicator
    if (show_cursor) {
        float cursor_dist = length(UV - cursor_uv);
        float cursor_size = 0.035; // Size in UV units
        
        // Outer black ring
        if (cursor_dist < cursor_size && cursor_dist > cursor_size * 0.8) {
            rgb = vec3(0.0);
        }
        // Inner white ring
        else if (cursor_dist < cursor_size * 0.8 && cursor_dist > cursor_size * 0.4) {
            rgb = vec3(1.0);
        }
    }

    COLOR = vec4(rgb, alpha);
}
