extends RigidBody3D
class_name Ship

const CTRL_ACCELERATION = 15.0

@export var controller : Controller

var ShipEngine := preload("res://ship_components/ShipEngine.gd")

var components : Array[Buildable]
var engines : Array[ThrustComponent]
var peak_directional_thrust := {"positive" = Vector3.ZERO,
								"negative" = Vector3.ZERO}

var update_physics_parameters := false
var target_acceleration := Vector3.ZERO

var r = Math.zero_matrix(6,1)


func _ready():
#	pass
	print(Math.zero_matrix(6,4)[0][2])
	get_child(0).preview = false

func _input(event):
	if event.is_action_pressed("fly_up"):
		r[1][0] = CTRL_ACCELERATION
	elif event.is_action_released("fly_up"):
		r[1][0] = 0
	
	if event.is_action_pressed("fly_down"):
		r[1][0] = -CTRL_ACCELERATION
	elif event.is_action_released("fly_down"):
		r[1][0] = 0
	
	if event.is_action_pressed("fly_forward"):
		r[2][0] = -CTRL_ACCELERATION
	elif event.is_action_released("fly_forward"):
		r[2][0] = 0
	
	if event.is_action_pressed("fly_back"):
		r[2][0] = CTRL_ACCELERATION
	elif event.is_action_released("fly_back"):
		r[2][0] = 0
	
	if event.is_action_pressed("fly_left"):
		r[0][0] = -CTRL_ACCELERATION
	elif event.is_action_released("fly_left"):
		r[0][0] = 0

	if event.is_action_pressed("fly_right"):
		r[0][0] = CTRL_ACCELERATION
	elif event.is_action_released("fly_right"):
		r[0][0] = 0

func _integrate_forces(state):
	if update_physics_parameters:
		recalculate_physics_params()
		update_physics_parameters = false
	
	# Controller
	var x = Math.zero_matrix(6,1)
	x[0][0] = -linear_velocity.x
	x[1][0] = -linear_velocity.y
	x[2][0] = -linear_velocity.z
	x[3][0] = -rotation.x
	x[4][0] = -rotation.y
	x[5][0] = -rotation.z
	
	var u = Math.multiply(controller.K, Math.add(r, x))
	for i in range(u.size()):
		engines[i].throttle = u[i][0] / engines[i].thrust
		print(engines[i].throttle)
		print("")
		apply_force(basis * engines[i].buildable.basis.y * engines[i].throttle * engines[i].thrust, basis * engines[i].buildable.position)

func recalculate_physics_params():
	var M = 0
	var CM = Vector3.ZERO
	var I = Vector3.ZERO
	for c in components:
		if not c.preview:
			M += c.mass
	for c in components:
		if not c.preview:
			CM += (c.mass * c.position)/M
	for c in components:
		if not c.preview:
			var origin = CM-c.position
			I += c.inertia + c.mass * (Vector3.ONE * origin.dot(origin) - vec_sqr(origin))
	mass = M
	center_of_mass = CM
	inertia = I
	controller.solve_K()
#	print("Controller Matrix K")
#	print("------------------")
#	for c in controller.K:
#		print(c)
#	print("------------------")
#	print("")

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)
