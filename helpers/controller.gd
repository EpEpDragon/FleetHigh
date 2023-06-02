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
var state_matrix : Array

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
var rotation_scale = 0.5
var rotation_rate_scale = 1
var linear_scale = 10
var angular_scale = 0.03

@onready var ship : Ship = get_parent()

func _ready():
	state_matrix = Math.zero_matrix(6,1)

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
		K[i][3] = torque.dot(axis.X) * log(ship.inertia.x+1) * angular_scale
		K[i][4] = torque.dot(axis.Y) * log(ship.inertia.y+1) * angular_scale
		K[i][5] = torque.dot(axis.Z) * log(ship.inertia.z+1) * angular_scale
			
		print(K)
		
var max_angle = deg_to_rad(15)
func compute_command(target_velocity : Vector3, velocity : Vector3, angular_rate : Vector3, rotation : Vector3) -> Array:
	# Linear Velocity & Angular Rate control
	#---------------------------------------------------------------------------------------------
	#
	# velocity_ref -----------------------------------------> * basis --> linear_velocity_control
	#              \--> rotation_ref --> angular_rate_ref --> * basis --> angular_rate_control
	#
	#---------------------------------------------------------------------------------------------
	var velocity_reference = (target_velocity - velocity)
	var rotation_reference = (axis.Y.cross(velocity_reference) * rotation_scale).clamp(Vector3(-max_angle,0,-max_angle), Vector3(max_angle,0,max_angle)) # Clamp for stability
	var angular_rate_reference = (rotation_reference - rotation) * rotation_rate_scale * ship.basis # Multiply basis for body coords
	velocity_reference *= ship.basis # To body
	
	# Reference matrices
	var reference_matrix = [[velocity_reference.x], [velocity_reference.y], [velocity_reference.z], [angular_rate_reference.x], [angular_rate_reference.y], [angular_rate_reference.z]]
	state_matrix[0][0] = velocity.x
	state_matrix[1][0] = velocity.y
	state_matrix[2][0] = velocity.z
	state_matrix[3][0] = angular_rate.x
	state_matrix[4][0] = angular_rate.y
	state_matrix[5][0] = angular_rate.z
	return Math.multiply(K, Math.subtract(reference_matrix, state_matrix))
