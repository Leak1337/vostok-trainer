shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D world_screen : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec3 source = textureLod(world_screen, SCREEN_UV, 0.0).rgb;
	float luminance = max(dot(source, vec3(0.2126, 0.7152, 0.0722)), 0.0);
	float amplified = 1.0 - exp(-pow(luminance, 0.8) * 4.5);
	vec3 night = vec3(0.012, 0.026, 0.017) + amplified * vec3(0.32, 0.94, 0.42);
	vec2 edge = abs(SCREEN_UV * 2.0 - 1.0);
	float vignette = 1.0 - 0.20 * smoothstep(0.45, 1.40, length(edge));
	COLOR = vec4(night * vignette, 1.0);
}
