#[compute]
#version 450

const float PI = 3.141592654;
const uint S = 1024;
const uint W = S*6;
const uint H = S;

const vec3 face_origins[6] = {{ -1,  1,  1}, {  1,  1,  1}, {  1,  1, -1},
							  {  1,  1,  1}, { -1,  1,  1}, { -1, -1,  1}};

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(set = 0, binding = 5, std430) buffer AtomicCounter {
	uint total_cells;
};

layout(set = 0, binding = 0, std430) restrict buffer PlanetParams {
	float warp_freq;
	float warp_gain;
	float warp_amp;
	vec4 plate_positions[]; // Using normals
} planet_params;

layout(set = 0, binding = 1, rgba32f) uniform image2D planet_texure;


float central_ang(vec3 n1, vec3 n2) {
	float dist = acos(dot(n1, n2));
	return dist;
	
	// idk this one doesnt seem to work...
	// float dist = atan(length(cross(n1, n2)) / dot(n1, n2));
}

// Calculate the UV coordinates of this cell
ivec2 uv_projection() {
	return ivec2(gl_GlobalInvocationID.z*H + gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);
}

// Calculates the cells sphere projection by normalizing the cube position
vec3 sphere_projection() {
	// Calculate the position on the cube face
	vec2 face_pos = vec2(mod(gl_GlobalInvocationID.x, H), gl_GlobalInvocationID.y);
	// Initialize the cube pos to the appropriate face origin
	vec3 cube_pos = face_origins[gl_GlobalInvocationID.z]*(S/2.0);
	// Move along face (no branching because all threads have same z)
	switch (gl_GlobalInvocationID.z) {
		case 0:
			cube_pos += vec3(face_pos.x, -face_pos.y, 0.0);
			break;
		case 1:
			cube_pos += vec3(0.0, -face_pos.y, -face_pos.x);
			break;
		case 2:
			cube_pos += vec3(-face_pos.x, -face_pos.y, 0.0);
			break;
		case 3:
			cube_pos += vec3(-face_pos.x, 0.0, -face_pos.y);
			break;
		case 4:
			cube_pos += vec3(0.0, -face_pos.x, -face_pos.y);
			break;
		case 5:
			cube_pos += vec3(face_pos.x, 0.0, -face_pos.y);
			break;
	};
	// Return normalized position on cube as position on sphere
	return normalize(cube_pos);
}

vec3 lerp(vec3 a, vec3 b, float t) {
	return a + (b - a)*t;
}

void main() {
	ivec2 uv = uv_projection();
	vec3 sphere_position = sphere_projection(); // Using normals
	ivec2 face_pos = ivec2(mod(gl_GlobalInvocationID.x, H), gl_GlobalInvocationID.y);

	float min_dist = 10;
	for (int i=0; i < planet_params.plate_positions.length(); i++) {
		float dist = central_ang(sphere_position, planet_params.plate_positions[i].xyz);
		min_dist = min(min_dist, dist);
	}
	// if (min_dist < 0.05) {
	// 	imageStore(planet_texure, uv, vec4(vec3(1.0,0.0,0.0), 1.0));
	// } else {
	// 	imageStore(planet_texure, uv, vec4(vec3(0.0,0.0,0.0), 1.0));
	// }
	imageStore(planet_texure, uv, vec4(vec3(min_dist/PI), 1.0));
	atomicAdd(total_cells, 1);
	
	// imageStore(planet_texure, uv, vec4(lerp(vec3(1.0,0.0,0.0), vec3(0.0,1.0,0.0), gl_GlobalInvocationID.z/6.0), 1.0));
	// float bright = sqrt(face_pos.x*face_pos.x + face_pos.y*face_pos.y) / sqrt(H*H*2);
	// if (int(mod(face_pos.x, 64)) < 6 || int(mod(face_pos.x, 64)) > 64-6 || int(mod(face_pos.y, 64)) < 6 || int(mod(face_pos.y, 64)) > 64-6) {
	// 	imageStore(planet_texure, uv, vec4(vec3(1.0,0.0,0.0)*bright, 1.0));
	// } else {
	// 	imageStore(planet_texure, uv, vec4(vec3(0.0,1.0,0.0)*bright, 1.0));
	// }
	// if (face_pos.x < 12 || face_pos.x > H-12 || face_pos.y < 12 || face_pos.y > H-12) {
	// 	imageStore(planet_texure, uv, vec4(vec3(0.0,0.0,1.0)*bright, 1.0));
	// }
	// if (gl_GlobalInvocationID.z == 0) {
	// 	imageStore(planet_texure, uv, vec4(vec3(1.0,1.0,1.0)*bright, 1.0));
	// }
}
