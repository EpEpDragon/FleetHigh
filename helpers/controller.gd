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

const NORMALIZATION_FACTOR = 0.02
#func _ready():
#	pass
	
func solve_K() -> void:
#	K = [[ 27.24076289,  19.36491655,   2.81794921, -27.24076248 , 19.36491673,
#   -2.81794938],
# [-27.24076291,  19.36491658,   2.81794921 ,-27.24076252, -19.36491673,
#	2.81794859],
# [  2.81794923,  19.36491693, -27.24076284 , -2.81794949 , 19.36491663,
#   27.24076331],
# [  2.81794924,  19.36491695,  27.24076291   ,2.81794902, -19.36491683,
#   27.24076338],
# [-27.24076299,  19.36491691,  -2.8179493   ,27.24076323 , 19.36491673,
#	2.81794825],
# [ 27.24076274,  19.36491689,  -2.8179493  , 27.24076327 ,-19.36491673,
#   -2.8179505 ],
# [ -2.81794913,  19.36491653,  27.24076295,   2.81794828 , 19.36491683,
#  -27.24076249],
# [ -2.81794911,  19.36491651 ,-27.2407628,   -2.81795023 ,-19.36491663,
#  -27.24076235]]
#	B = Math.zero_matrix(6,ship.engines.size())
	K = Math.zero_matrix(ship.engines.size(),6)
	for i in range(ship.engines.size()):
		var position = ship.engines[i].buildable.position
		var thrust = ship.engines[i].thrust_vector
	#		var torque = position.cross(thrust) * (position - ship.center_of_mass).length_squared()
		var torque = (position - ship.center_of_mass).cross(thrust)
		# Linear
		K[i][0] = thrust.dot(axis.X)
		K[i][1] = thrust.dot(axis.Y)
		K[i][2] = thrust.dot(axis.Z)
		# Angular
		K[i][3] = torque.dot(axis.X)
		K[i][4] = torque.dot(axis.Y)
		K[i][5] = torque.dot(axis.Z)
			
		# TODO Make this python call more efficient
	#	var out : Array
	#	OS.execute(interpreter_path,[script_path, B],out,false,true)
	#	K = JSON.parse_string(out[0])
		print(K)
		

func compute_command(R : Array, velocity : Vector3, angular_rate : Vector3, rotation : Vector3) -> Array:
	var angular_rate_reference = Vector3(R[3][0]-rotation.x * K_pre, R[4][0]-rotation.x * K_pre, R[5][0]-rotation.z * K_pre) * ship.basis
	var reference_matrix = [R[0], R[1], R[2], [angular_rate_reference.x], [angular_rate_reference.y], [angular_rate_reference.z]]
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
