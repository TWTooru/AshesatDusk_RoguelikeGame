shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 4.0;
uniform vec4 overlay_color : source_color = vec4(0.06, 0.05, 0.08, 0.65);

void fragment() {
	vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);
	COLOR = mix(blurred, vec4(overlay_color.rgb, 1.0), overlay_color.a);
}
