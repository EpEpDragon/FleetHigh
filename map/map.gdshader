shader_type spatial;

uniform sampler2D biomes;
uniform sampler2D height_0;

uniform sampler2D height_1;
uniform sampler2D height_normal_1;

const float waterlevel = 0.0;

float height(vec2 uv) {
	return texture(height_1, uv).x * sin(uv.x*PI) * sin(uv.y*PI) * texture(height_0, uv).x;
}

void vertex() {
	VERTEX.y += height(UV);
//	VERTEX.y = clamp(VERTEX.y, waterlevel, 1.0);
//	COLOR = texture(biomes, vec2(VERTEX.y*0.99+0.01,0.0));
//	COLOR = VERTEX.yyyy;
	VERTEX.y *= 20.0;
}

void fragment() {
	NORMAL_MAP = texture(height_normal_1, UV).xyz;
	ALBEDO = texture(biomes, vec2(height(UV)*0.99+0.01,0.0)).rgb;
//	ALBEDO = COLOR.rgb*2.5;
}