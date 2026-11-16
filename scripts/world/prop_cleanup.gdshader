shader_type canvas_item;

uniform vec2 roof_span = vec2(0.34, 0.68);
uniform float row_limit = 0.177;
uniform float portal_light = 0.0;

void fragment() {
	vec4 painted = texture(TEXTURE, UV);
	if (UV.y < row_limit && (UV.x < roof_span.x || UV.x > roof_span.y)) {
		painted.a = 0.0;
	}
	vec2 aperture = (UV - vec2(0.5, 0.69)) / vec2(0.227, 0.266);
	float radius = length(aperture);
	float fade = 1.0 - smoothstep(0.48, 0.97, radius);
	float phase = atan(aperture.y, aperture.x) * 3.0 - radius * 14.0 + TIME * 3.0;
	float light = pow(0.5 + 0.5 * cos(phase), 3.0) * fade * portal_light;
	COLOR = vec4(mix(painted.rgb, vec3(1.0, 0.93, 0.70), light), painted.a);
}
