extends Node
class_name Controller

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
var K : Array

@onready var ship : Ship = get_parent()


func solve_K() -> void:
	K = Math.zero_matrix(ship.engines.size(), 6)
	for i in range(ship.engines.size()):
		var position = ship.engines[i].buildable.position
		var thrust = ship.engines[i].thrust_vector
		var torque = position.cross(thrust) * (position - ship.center_of_mass).length_squared()
		# Linear
		K[i][0] = thrust.dot(axis.X)
		K[i][1] = thrust.dot(axis.Y)
		K[i][2] = thrust.dot(axis.Z)
		# Angular
		K[i][3] = torque.dot(axis.X)
		K[i][4] = torque.dot(axis.Y)
		K[i][5] = torque.dot(axis.Z)


func compute_command(R : Array) -> Array:
	return Math.multiply(Math.subtract(R, x), K)
