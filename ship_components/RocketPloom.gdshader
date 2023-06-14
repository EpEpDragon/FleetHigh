shader_type spatial;
render_mode unshaded;

uniform float height = 10.0;
uniform float rad = 0.0;
uniform float ripple = 1.0;
uniform float flare = 0.0;
uniform float period = 0.5;
uniform float slope = 0.8;
uniform sampler2D color_slope;

struct Polar {
	float h;
	float r;
	float ang;
};

Polar to_polar(vec3 cartesian) {
	float r = sqrt(cartesian.x*cartesian.x + cartesian.z*cartesian.z);
	if (r == 0.0) {
		return Polar(cartesian.y, 0.0, 0.0);
	}
	float ang = acos(cartesian.x/r);
	if (cartesian.z < 0.0) {
		ang = -ang;
	}
	return Polar(cartesian.y, r, ang);
}

vec3 to_cartesian(Polar polar) {
	return vec3(polar.r * cos(polar.ang), polar.h, polar.r * sin(polar.ang));
}

void vertex() {
	float height_2 = height/2.0;
	Polar polar = to_polar(VERTEX);
	polar.h *= height;
	float h = (polar.h+height_2)/height;
	if (polar.r != 0.0) {
		polar.r = (sin(h * period)*ripple*1.0/(h+0.1) + 1.0 + rad) * (1.0+h*slope);
	}

	polar.h += height_2;
	VERTEX = to_cartesian(polar);
//	vec4 color = texture(color_slope, vec2(h,0.5))
	COLOR = texture(color_slope, vec2((h+0.01)*0.98,0.5));
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
