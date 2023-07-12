shader_type spatial;
render_mode unshaded;
#include "FastNoiseLite.gdshaderinc"

uniform int dist_type : hint_range(0, 6) = 0;
uniform float radius = 1.0;

uniform float plates_frequency = 0.01f;

uniform int noise_type : hint_range(0,5) = 0;
uniform float frequency = 0.01;
uniform int octaves = 5;
uniform float lacunarity = 2.0;
uniform float gain = 0.5;

uniform float plates_warp_freq : hint_range(0.0, 0.1) = 1.0f;
uniform float plates_warp_amp = 1.0f;
uniform float plates_warp_gain : hint_range(0.0, 10.0) = 1.0f;

uniform sampler2D plates_color;

void vertex() {
	VERTEX = normalize(VERTEX);
	NORMAL = VERTEX;
	VERTEX *= radius;
}

void fragment() {
	vec3 world_vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.f)).xyz;
//	fnl_state plate_state = fnlCreateState(0);
//	plate_state.noise_type = FNL_NOISE_CELLULAR;
//	plate_state.cellular_return_type = dist_type;
//	plate_state.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_CELLVALUE;
//	plate_state.fractal_type = FNL_FRACTAL_NONE;
//	plate_state.frequency = plates_frequency;
//	plate_state.octaves = 4;
//	plate_state.lacunarity = 2.f;
//	plate_state.gain = .5f;

	fnl_state plate_warp_state = fnlCreateState(0);
	plate_warp_state.domain_warp_amp = plates_warp_amp;
	plate_warp_state.fractal_type = FNL_FRACTAL_NONE;
	plate_warp_state.frequency = plates_warp_freq;
	plate_warp_state.octaves = 4;
	plate_warp_state.lacunarity = 2.f;
	plate_warp_state.gain = plates_warp_gain;


//	float noise = fnlGetNoise3D(plate_state, world_vertex.x, world_vertex.y, world_vertex.z) / 2.f + 0.5f;
////	ALBEDO = vec3(noise);
//	ALBEDO = texture(plates_color, vec2(noise*0.99+0.005)).rgb * (noise*0.6+0.4);
//
	fnl_state convection_x = fnlCreateState(0);
	convection_x.noise_type = noise_type;
	convection_x.cellular_return_type = dist_type;
	convection_x.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_DISTANCE;
	convection_x.fractal_type = FNL_FRACTAL_RIDGED;
	convection_x.frequency = frequency;
	convection_x.octaves = octaves;
	convection_x.lacunarity = lacunarity;
	convection_x.gain = gain;

	fnl_state convection_y = fnlCreateState(1);
	convection_y.noise_type = FNL_NOISE_OPENSIMPLEX2;
	convection_y.fractal_type = FNL_FRACTAL_NONE;
	convection_y.frequency = 0.01;
	convection_y.octaves = 4;
	convection_y.lacunarity = 2.f;
	convection_y.gain = .5f;

	fnl_state convection_z = fnlCreateState(2);
	convection_z.noise_type = FNL_NOISE_OPENSIMPLEX2;
	convection_z.fractal_type = FNL_FRACTAL_NONE;
	convection_z.frequency = 0.01;
	convection_z.octaves = 4;
	convection_z.lacunarity = 2.f;
	convection_z.gain = .5f;
//	fnlDomainWarp3D(plate_warp_state, world_vertex.x, world_vertex.y, world_vertex.z);
	float noise_x = fnlGetNoise3D(convection_x, world_vertex.x+TIME*20.0, world_vertex.y, world_vertex.z) / 2.f + 0.5f;
	float noise_y = fnlGetNoise3D(convection_y, world_vertex.x, world_vertex.y, world_vertex.z);
	float noise_z = fnlGetNoise3D(convection_z, world_vertex.x, world_vertex.y, world_vertex.z);
	ALBEDO = vec3(noise_x*noise_x);
}
