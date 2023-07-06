shader_type spatial;

uniform sampler2D height_0;

uniform sampler2D height_1;
uniform sampler2D height_normal_1;

const float waterlevel = 0.0;
void vertex() {
	VERTEX *= (texture(height_1, UV).x * texture(height_0, UV).x)*0.1 + 1.0;
}

void fragment() {
	NORMAL_MAP = texture(height_normal_1, UV).xyz;
	float h = texture(height_1, UV).x * texture(height_0, UV).x;
//	float h = texture(height_0, UV).x;
	ALBEDO = vec3(h,h,h)*5.0;
}
