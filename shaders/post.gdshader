shader_type canvas_item;

uniform float vignette = 0.30;
uniform float grain = 0.025;
uniform vec4 tint : source_color = vec4(0.17, 0.11, 0.16, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / 4.0);
	vec2 uv = SCREEN_UV;
	float d = distance(uv, vec2(0.5, 0.48));
	float v = smoothstep(0.45, 0.95, d) * vignette;
	v = floor(v * 10.0 + hash(cell) * 0.9) / 10.0;
	float n = hash(cell + floor(TIME * 8.0)) - 0.5;
	COLOR = vec4(tint.rgb + n * 0.3, clamp(v + abs(n) * grain, 0.0, 1.0));
}
