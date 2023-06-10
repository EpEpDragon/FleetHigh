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

# State matrix, in to body coordinates (6x1)
# -------------------
# velocity x
# velocity y
# velocity z
# angle x
# angle y
# angle z
# -------------------
var error_matrix : Array

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
var K : Array
var linear_scale = 20
var rotation_angle_scale = 0.01
var rotation_rate_scale = 0.5

@onready var ship : Ship = get_parent()

func _ready():
	error_matrix = Math.zero_matrix(6,1)

func solve_K() -> void:
	K = Math.zero_matrix(ship.engines.size(),6)
	for i in range(ship.engines.size()):
		var position = ship.engines[i].buildable.position
		var thrust = ship.engines[i].thrust_vector
		var torque = (position - ship.center_of_mass).cross(thrust)
		
		# Linear thrust (thrust)
		# Scaled by: log(mass + 1)^2 / [peak thrust in said direction] * K
		var scale_factor_linear = log(ship.mass+1)*log(ship.mass+1) * linear_scale
		K[i][0] = thrust.dot(axis.X) * scale_factor_linear / clamp(max(ship.peak_directional_thrust.positive.x, ship.peak_directional_thrust.negative.x),1,INF)
		K[i][1] = thrust.dot(axis.Y) * scale_factor_linear / clamp(max(ship.peak_directional_thrust.positive.y, ship.peak_directional_thrust.negative.y),1,INF)
		K[i][2] = thrust.dot(axis.Z) * scale_factor_linear / clamp(max(ship.peak_directional_thrust.positive.z, ship.peak_directional_thrust.negative.z),1,INF)
		
		# Angular thrust (torque)
		# Scaled by: log(inertia + 1) * K
		K[i][3] = torque.dot(axis.X) * log(ship.inertia.x+1) * rotation_rate_scale
		K[i][4] = torque.dot(axis.Y) * log(ship.inertia.y+1) * rotation_rate_scale
		K[i][5] = torque.dot(axis.Z) * log(ship.inertia.z+1) * rotation_rate_scale

var max_angle = deg_to_rad(45)
var max_ref = 15
func compute_command(target_velocity : Vector3, yaw : float) -> Array:
	# Linear Velocity & Angular Rate control
	#---------------------------------------------------------------------------------------------
	#
	# velocity_ref -----------------------------------------> * basis --> linear_velocity_control
	#              \--> rotation_ref --> angular_rate_ref --> * basis --> angular_rate_control
	#
	#---------------------------------------------------------------------------------------------

	var rotation_reference = (axis.Y.cross(target_velocity - ship.linear_velocity) * rotation_angle_scale).clamp(Vector3(-max_angle,0,-max_angle), Vector3(max_angle,0,max_angle)) # Clamp for stability
	rotation_reference.y = yaw
	var angular_rate_reference = (rotation_reference - ship.rotation)
	
	var velocity_error = (target_velocity - ship.linear_velocity).normalized()*log((target_velocity - ship.linear_velocity).length()+1)
	var angular_velocity_error =  angular_rate_reference - ship.angular_velocity
	velocity_error *= ship.basis
	angular_velocity_error *= ship.basis
	ship.get_child(1).target_position = ship.linear_velocity*ship.basis
	ship.get_child(1).position = ship.center_of_mass
	error_matrix[0][0] = velocity_error.x
	error_matrix[1][0] = velocity_error.y
	error_matrix[2][0] = velocity_error.z
	error_matrix[3][0] = angular_velocity_error.x
	error_matrix[4][0] = angular_velocity_error.y
	error_matrix[5][0] = angular_velocity_error.z
	return Math.multiply(K, error_matrix)
