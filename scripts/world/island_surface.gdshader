shader_type canvas_item;

uniform vec4 low_color : source_color = vec4(0.48, 0.54, 0.20, 1.0);
uniform vec4 high_color : source_color = vec4(0.79, 0.79, 0.39, 1.0);
uniform vec2 grain_scale = vec2(1.0);
varying vec2 map_position;

void vertex() {
	map_position = VERTEX;
}

float hash_cell(vec2 cell) {
	vec3 p = fract(vec3(cell.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float field(vec2 position) {
	vec2 cell = floor(position);
	vec2 f = fract(position);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_cell(cell), hash_cell(cell + vec2(1, 0)), f.x),
		mix(hash_cell(cell + vec2(0, 1)), hash_cell(cell + vec2(1)), f.x), f.y);
}

void fragment() {
	vec2 p = map_position * grain_scale;
	float wash = field(p / 185.0) * 0.44 + field(p / 45.0) * 0.30;
	float grain = field(p / 8.0) * 0.16 + field(p / 2.7) * 0.10;
	COLOR = mix(low_color, high_color, clamp((wash + grain) * 1.28 - 0.07, 0.0, 1.0));
}
