#[compute]
#version 450

const float PI = 3.141592654;
const int S = 64*3;
const uint W = S*6;
const uint H = S;
const int kernel[21] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 , -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};

// struct face_traversal {
// 	int face_i_n;
// 	int face_i_p;
// 	int offset_n;
// 	int offset_p;
// 	bool flip;
// };

const vec3 face_origins[6] = {{ -1,  1,  1}, {  1,  1,  1}, {  1,  1, -1},
							  { -1,  1, -1}, { -1,  1, -1}, { -1, -1,  1}};

const vec3 face_tangents_x[6] = {{  1,  0,  0}, {  0,  0, -1}, { -1,  0,  0},
								 {  0,  0,  1}, {  1,  0,  0}, {  1,  0,  0}};

const vec3 face_tangents_y[6] = {{  0, -1,  0}, {  0, -1,  0}, {  0, -1,  0},
								 {  0, -1,  0}, {  0,  0,  1}, {  0,  0, -1}};
// Cube traversal structure
// Multiplier applied as: texel = texel * multiplier + offset
// --------------
// face_id_n
// face_id_p
// multiplier_n
// multultiplier_p
// offset_n
// offset_p
// invert axis n
// invert axis p
// swap axis
//---------------

// TODO finish this
const int cube_traversal_x[6][9] = {{3,1,1,1,S,-S,0,0,0}, {0,2,1,1,S,-S,0,0,0}, {1,3,1,1,S,-S,0,0,0},
									{2,0,1,1,S,-S,0,0,0}, {3,1,-1,1,-1,-S,0,1,1}, {3,1,1,-1,S,2*S-1,1,0,1}};

const int cube_traversal_y[6][9] = {{4,5,1,1,S,-S,0,0,0}, {4,5,1,-1,S,2*S-1,1,0,1}, {4,5,-1,-1,-1,2*S-1,1,1,0},
									{4,5,-1,1,-1,-S,0,1,1}, {2,0,-1,1,-1,-S,1,0,0}, {0,2,1,-1,S,2*S-1,0,1,0}};

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(set = 0, binding = 5, std430) buffer AtomicCounter {
	uint total_cells;
};

layout(push_constant) uniform constants {
	int npass;
};

struct plateParams {
	float nx;
	float ny;
	float nz;
	
	float vx;
	float vy;
	float vz;

	float density;
	float _;
};

layout(set = 0, binding = 0, std430) restrict buffer PlanetParams {
	plateParams plate_params[]; // Using normals
};

layout(set = 0, binding = 1, rgba32f) uniform image2D plate_velocity;
layout(set = 0, binding = 2, rgba32f) uniform image2D plate_pressure_x;
layout(set = 0, binding = 3, rgba32f) uniform image2D plate_pressure_xy;


float central_ang(vec3 n1, vec3 n2) {
	float dist = acos(dot(n1, n2));
	return dist;
	
	// idk this one doesnt seem to work...
	// float dist = atan(length(cross(n1, n2)) / dot(n1, n2));
}


// Calculate the texel coordinates of this cell
ivec2 get_texel(int off_x, int off_y) {
	int face_x = int(mod(gl_GlobalInvocationID.x, S));
	int face_y = int(mod(gl_GlobalInvocationID.y, S));
	int face_i = int(gl_GlobalInvocationID.z);
	
	// X offset
	if (off_x != 0 ) {
		face_x += off_x;
		float i = 0.5;
		if (face_x < 0 || face_x > S-1) {
			i += sign(face_x)*0.5;
			face_x = face_x * cube_traversal_x[face_i][int(i)+2] + cube_traversal_x[face_i][int(i)+4];
			if (cube_traversal_x[face_i][int(i)+6] == 1) {
				face_y = -face_y + S-1;
			}
			if (cube_traversal_x[face_i][8] == 1) {
				int temp = face_x;
				face_x = face_y;
				face_y = temp;
			}
			face_i = cube_traversal_x[face_i][int(i)];
		}
	}
	// Y offset
	if (off_y != 0) {
		face_y += off_y;
		float i = 0.5;
		if (face_y < 0 || face_y > S-1) {
			i += sign(face_y)*0.5;
			face_y = face_y * cube_traversal_y[face_i][int(i)+2] + cube_traversal_y[face_i][int(i)+4];
			if (cube_traversal_y[face_i][int(i)+6] == 1) {
				face_x = -face_x + S-1;
			}
			if (cube_traversal_y[face_i][8] == 1) {
				int temp = face_x;
				face_x = face_y;
				face_y = temp;
			}
			face_i = cube_traversal_y[face_i][int(i)];
		}
	}
	return ivec2(face_i*H + face_x, face_y);
}

// Calculates the cells sphere projection by normalizing the cube position
vec3 sphere_projection() {
	// Calculate the position on the cube face
	vec2 face_pos = vec2(mod(gl_GlobalInvocationID.x, H), gl_GlobalInvocationID.y);
	// Initialize the cube pos to the appropriate face origin
	vec3 cube_pos = face_origins[gl_GlobalInvocationID.z]*(S/2);
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
			cube_pos += vec3(0.0, -face_pos.y, face_pos.x);
			break;
		case 4:
			cube_pos += vec3(face_pos.x, 0.0, face_pos.y);
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
	ivec2 texel = get_texel(0,0);
	vec3 sphere_position = sphere_projection(); // Using normals
	if (npass == 0) {
		float min_dist = 10;
		uint close_id = 0;
		for (int i=0; i < plate_params.length(); i++) {
			vec3 plate_positions = vec3(plate_params[i].nx, plate_params[i].ny, plate_params[i].nz);
			float dist = central_ang(sphere_position, plate_positions);
			if (dist < min_dist) {
				min_dist = dist;
				close_id = i;
			}
			// min_dist = min(min_dist, dist);
		}
		// imageStore(plate_velocity, texel, vec4(vec3(min_dist*min_dist), 1.0));
		imageStore(plate_velocity, texel, vec4(vec3(plate_params[close_id].vx, plate_params[close_id].vy, plate_params[close_id].vz) / 2.0 + 0.5, min_dist));
		if (sphere_position.x < 0) {
			imageStore(plate_velocity, texel, vec4(cross(vec3(0.0,1.0,0.0), sphere_position), 1.0));
		} else {
			imageStore(plate_velocity, texel, vec4(cross(vec3(0.0,-1.0,0.0), sphere_position), 1.0));
		}
		// atomicAdd(total_cells, 1);
	}
	// X pass
	else if (npass == 1) {
		vec3 self_vel = imageLoad(plate_velocity, texel).xyz;
		float pressure = 0.0;
		for (int i=0; i<=20; i++) {
			ivec2 other_texel = get_texel(i-10, 0);
			// vec3 other_vel = imageLoad(plate_velocity, ivec2(texel.x+i-10,texel.y)).xyz;
			vec3 other_vel = imageLoad(plate_velocity, other_texel).xyz;
			// pressure += self_vel.x * other_vel.x * kernel[i] * sign(self_vel.x);
			pressure += dot(self_vel, other_vel) * kernel[i] * sign(dot(self_vel, cross(sphere_position, cross(face_tangents_x[gl_GlobalInvocationID.z], sphere_position))));
		}
		pressure /= 5.0;
		pressure = pressure / 2.0 + 0.5;
		imageStore(plate_pressure_x, texel, vec4(vec3(pressure), 1.0));
		// if (mod(texel.x, S) == 0.0) {
		// 	imageStore(plate_velocity, texel, vec4(vec3(1.0,0.0,0.0), 1.0));
		// }
	}
	// Y pass
	else if (npass == 2) {
		vec3 self_vel = imageLoad(plate_velocity, texel).xyz;
		// float pressure = imageLoad(plate_pressure, texel).r;
		float pressure = 0.0;
		for (int i=0; i<=20; i++) {
			ivec2 other_texel = get_texel(0, i-10);
			vec3 other_vel = imageLoad(plate_velocity, other_texel).xyz;
			// pressure += self_vel.y * other_vel.y * kernel[i] * sign(self_vel.y);
			pressure += dot(self_vel, other_vel) * kernel[i] * sign(dot(self_vel, cross(sphere_position, cross(face_tangents_y[gl_GlobalInvocationID.z], sphere_position))));

		}
		pressure /= 5.0;
		pressure = pressure / 2.0 + 0.5;
		imageStore(plate_pressure_xy, texel, vec4(vec3(pressure + imageLoad(plate_pressure_x, texel))/2.0, 1.0));
		// imageStore(plate_pressure_xy, texel, vec4(vec3(pressure), 1.0));
		// if (texel.x == S+1 && texel.y == 0) {
		// 	imageStore(plate_pressure, texel, vec4(vec3(0.0,1.0,0.0), 1.0));
		// 	for (int i=0; i<=20; i++) {
		// 		// imageStore(plate_velocity, get_texel(0, i-10), vec4(vec3(1.0,0.0,0.0), 1.0));
		// 		imageStore(plate_pressure, get_texel(0, i-10), vec4(vec3(1.0,0.0,0.0), 1.0));
		// 	}
		// }
		if (mod(sphere_position.x, 0.01) < 0.001) {
			imageStore(plate_pressure_xy, texel, vec4(vec3(1.0,0.0,0.0), 1.0));
		}
	}

	// if (texel.x == S) {
	// 	imageStore(plate_pressure, texel, vec4(vec3(1.0,0.0,0.0), 1.0));
	// }
	
}