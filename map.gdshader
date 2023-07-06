shader_type spatial;

uniform sampler2D height;

void vertex() {
	VERTEX.y += texture(height, UV).x * 10.0;
}

void fragment() {
	// Place fragment code here.
}
