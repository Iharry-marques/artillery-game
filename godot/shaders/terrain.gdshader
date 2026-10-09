shader_type canvas_item;
// Terrain look over the collision mask (presentation only, DECISIONS D-034).
// TEXTURE (one texel per collision cell, linear filtering):
//   r = solid now, g = solid in the original map, b = scorch amount.
// Linear filtering + a 0.5 threshold turns the 0.05 u cell grid into smooth contours.

uniform vec4 grass_light : source_color = vec4(0.56, 0.86, 0.30, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.27, 0.62, 0.22, 1.0);
uniform vec4 soil_top : source_color = vec4(0.83, 0.60, 0.36, 1.0);
uniform vec4 soil_deep : source_color = vec4(0.48, 0.30, 0.22, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.70, 0.62, 0.56, 1.0);
uniform vec4 outline_color : source_color = vec4(0.24, 0.13, 0.10, 1.0);
uniform vec4 scorch_color : source_color = vec4(0.20, 0.13, 0.11, 1.0);
uniform float cell_size = 0.05;
uniform float grass_depth = 0.24;
uniform float outline_width = 0.05;
uniform float soil_gradient_top = 8.0;
uniform float soil_gradient_bottom = 18.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec4 data = texture(TEXTURE, UV);
	float coverage = smoothstep(0.4, 0.6, data.r);
	if (coverage < 0.01) {
		discard;
	}
	vec2 per_unit = TEXTURE_PIXEL_SIZE / cell_size;
	vec2 world = UV / per_unit;

	// Grass only where the ORIGINAL surface is just above and still open.
	float wobble = 0.05 * sin(world.x * 11.0) + 0.06 * value_noise(world * vec2(7.0, 1.0));
	vec2 above = UV - vec2(0.0, (grass_depth + wobble) * per_unit.y);
	bool grass = texture(TEXTURE, above).g < 0.5 && texture(TEXTURE, above).r < 0.5;

	float depth = clamp((world.y - soil_gradient_top) / (soil_gradient_bottom - soil_gradient_top), 0.0, 1.0);
	vec3 color = mix(soil_top.rgb, soil_deep.rgb, depth);
	float strata = 0.5 + 0.5 * sin(world.y * 6.0 + value_noise(world * 1.3) * 5.0);
	color *= 0.94 + 0.08 * strata;
	color *= 0.93 + 0.12 * value_noise(world * 24.0);
	float pebbles = value_noise(world * 11.0 + vec2(17.0, 3.0));
	color = mix(color, pebble_color.rgb, smoothstep(0.86, 0.89, pebbles) * 0.6);

	if (grass) {
		float blades = value_noise(vec2(world.x * 38.0, world.y * 3.0));
		color = mix(grass_dark.rgb, grass_light.rgb, 0.45 + 0.55 * blades);
		vec2 just_above = UV - vec2(0.0, 0.06 * per_unit.y);
		if (texture(TEXTURE, just_above).g < 0.5) {
			color = mix(color, vec3(0.8, 0.98, 0.55), 0.45);
		}
	}

	color = mix(color, scorch_color.rgb, data.b * 0.85);

	float ox = outline_width * per_unit.x;
	float oy = outline_width * per_unit.y;
	float neighbours = min(min(texture(TEXTURE, UV + vec2(ox, 0.0)).r, texture(TEXTURE, UV - vec2(ox, 0.0)).r), min(texture(TEXTURE, UV + vec2(0.0, oy)).r, texture(TEXTURE, UV - vec2(0.0, oy)).r));
	float edge = 1.0 - smoothstep(0.3, 0.6, neighbours);
	color = mix(color, outline_color.rgb, edge * 0.92);

	COLOR = vec4(color, coverage);
}
