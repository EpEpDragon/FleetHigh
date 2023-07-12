shader_type spatial;
render_mode unshaded;

void vertex() {
	VERTEX = normalize(VERTEX);
	NORMAL = VERTEX;
	VERTEX *= 50.0;
	COLOR = vec4(NORMAL / 2.0 + 0.5, 1.0);
}

void fragment() {
	ALBEDO = COLOR.rgb;//(INV_VIEW_MATRIX * vec4(NORMAL.x, NORMAL.y, NORMAL.z, 0.0)).xyz / 2.0 + 0.5;
}
