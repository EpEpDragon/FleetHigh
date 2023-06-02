extends Node
class_name Controller
#var DIR = OS.get_executable_path().get_base_dir()
#var interpreter_path = DIR.path_join("python/bin/python3.10")
#var script_path = DIR.path_join("stabilisation/stabilisation.py")
var interpreter_path = ProjectSettings.globalize_path("res://python/Scripts/python")
var script_path = ProjectSettings.globalize_path("res://stabilisation/stabilisation.py")
var axis := {
				"X" = Vector3.RIGHT,
				"Y" = Vector3.UP,
				"Z" = Vector3.BACK
			}

# State matrix (6x1)
# -------------------
# x
# y
# z
# angx
# angy
# angz
# -------------------
var x : Array

# Control matrix (mx6)
# -------------------
# fx1 fy1 fz1 frotx1 froty1 frotz1
#                .
#                .
#                .
# fxm fym fzm frotxm frotym frotzm
# --------------------
# Where: m = Number of thrusters
#		 fxyz = Influence on xyz linear
#		 frotxyz = Influence on xyz angular
var B : Array
var K : Array
var K_pre = 1

@onready var ship : Ship = get_parent()

#func _ready():
#	pass
	
func solve_K() -> void:
#	B = Math.zero_matrix(6,ship.engines.size())
	K = Math.zero_matrix(ship.engines.size(),6)
	for i in range(ship.engines.size()):
		var position = ship.engines[i].buildable.position
		var thrust = ship.engines[i].thrust_vector
		var torque = (position - ship.center_of_mass).cross(thrust)
		# Linear
		var scale_factor_linear = log(ship.mass+1)*log(ship.mass+1) * 10
		K[i][0] = thrust.dot(axis.X) * scale_factor_linear / clamp(max(ship.peak_directional_thrust.positive.x, ship.peak_directional_thrust.negative.x),1,INF)
		K[i][1] = thrust.dot(axis.Y) * scale_factor_linear / clamp(max(ship.peak_directional_thrust.positive.y, ship.peak_directional_thrust.negative.y),1,INF)
		K[i][2] = thrust.dot(axis.Z) * scale_factor_linear / clamp(max(ship.peak_directional_thrust.positive.z, ship.peak_directional_thrust.negative.z),1,INF)
		# Angular
		K[i][3] = torque.dot(axis.X) * log(ship.inertia.x+1) * 0.03
		K[i][4] = torque.dot(axis.Y) * log(ship.inertia.y+1) * 0.03
		K[i][5] = torque.dot(axis.Z) * log(ship.inertia.z+1) * 0.03
			
		# TODO Make this python call more efficient
	#	var out : Array
	#	OS.execute(interpreter_path,[script_path, B],out,false,true)
	#	K = JSON.parse_string(out[0])
		print(K)
		
var max_angle = deg_to_rad(15)
func compute_command(target_velocity : Vector3, velocity : Vector3, angular_rate : Vector3, rotation : Vector3) -> Array:
	var velocity_reference = (target_velocity - velocity)
	var rotation_reference = axis.Y.cross(velocity_reference).clamp(Vector3(-max_angle,0,-max_angle), Vector3(max_angle,0,max_angle))
	var angular_rate_reference = (rotation_reference - rotation) * ship.basis
	velocity_reference *= ship.basis
	var reference_matrix = [[velocity_reference.x], [velocity_reference.y], [velocity_reference.z], [angular_rate_reference.x], [angular_rate_reference.y], [angular_rate_reference.z]]
#	print("REF: " + str(reference_matrix))
	var x = Math.zero_matrix(6,1)
	x[0][0] = velocity.x
	x[1][0] = velocity.y
	x[2][0] = velocity.z
	x[3][0] = angular_rate.x
	x[4][0] = angular_rate.y
	x[5][0] = angular_rate.z
#	print("ERR: " + str(Math.subtract(reference_matrix, x)))
	return Math.multiply(K, Math.subtract(reference_matrix, x))
