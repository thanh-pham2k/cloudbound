shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tile_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D terrain_mask : filter_nearest, repeat_disable;
uniform vec2 world_size = vec2(1254.0);
uniform vec2 tile_pixels = vec2(414.0);
uniform float tile_scale = 0.5;
uniform float blend_fraction = 0.12;
uniform vec4 tint : source_color = vec4(1.0);
varying vec2 source_position;

void vertex() {
	source_position = VERTEX;
}

void fragment() {
	vec2 q = source_position / (tile_pixels * tile_scale);
	vec2 f = fract(q);
	vec2 edge = min(f, 1.0 - f);
	vec2 weight = 1.0 - smoothstep(vec2(0.0), vec2(blend_fraction), edge);
	// Shifted samples crossfade across nonmatching wrap edges. No UV warp,
	// anisotropic scaling, mirroring or deformation of the atlas geometry.
	vec4 a = texture(tile_texture, q);
	vec4 b = texture(tile_texture, q + vec2(0.5, 0.0));
	vec4 c = texture(tile_texture, q + vec2(0.0, 0.5));
	vec4 d = texture(tile_texture, q + vec2(0.5, 0.5));
	vec4 surface = mix(mix(a, b, weight.x), mix(c, d, weight.x), weight.y);
	float mask = texture(terrain_mask, source_position / world_size).r;
	COLOR = vec4(surface.rgb * tint.rgb, surface.a * mask * tint.a);
}
