shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float blur_lod : hint_range(0.0, 5.0) = 3.5;

void fragment() {
    vec3 bg = textureLod(screen_texture, SCREEN_UV, blur_lod).rgb;
    vec4 src = COLOR;

    COLOR.rgb = mix(bg, src.rgb, src.a);
    COLOR.a = 1.0;
}