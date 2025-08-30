shader_type spatial;

float grid(vec2 uv, float columns, float rows, float thickness)
{
	vec2 f = fract(vec2(uv.x * columns, uv.y * rows));
	return max(
		1.0 - step(thickness, f.x),
		1.0 - step(thickness, f.y)
	);
}

void fragment()
{
	float line = grid(UV, 20, 10, 0.05);
	ALBEDO.r = 1.0 - step(UV.y, 0.5);
	ALBEDO.g = 0.1;
	ALBEDO.b = step(UV.y, 0.5);
	ALBEDO = mix(ALBEDO, vec3(1.0, 1.0, 1.0), line);
}
