extends RigidBody3D
class_name Ship
var ship_data : ShipData

const CTRL_SPEED = 130

@export var controller : Controller

var components : Array[Buildable]
var engines : Array[ThrustComponent]
var peak_directional_thrust := {"positive" = Vector3.ZERO,
								"negative" = Vector3.ZERO}

var update_physics_parameters := false
var target_velocity := Vector3.ZERO

func _ready():
	if not ship_data:
		ship_data = ShipData.new()
	get_child(2).preview = false

func _input(event):
	if event.is_action_pressed("fly_up"):
		target_velocity += Vector3.UP
	elif event.is_action_released("fly_up"):
		target_velocity -= Vector3.UP
	
	if event.is_action_pressed("fly_down"):
		target_velocity += Vector3.DOWN
	elif event.is_action_released("fly_down"):
		target_velocity -= Vector3.DOWN
	
	if event.is_action_pressed("fly_forward"):
		target_velocity += Vector3.FORWARD
	elif event.is_action_released("fly_forward"):
		target_velocity -= Vector3.FORWARD
	
	if event.is_action_pressed("fly_back"):
		target_velocity += Vector3.BACK
	elif event.is_action_released("fly_back"):
		target_velocity -= Vector3.BACK
	
	if event.is_action_pressed("fly_left"):
		target_velocity += Vector3.LEFT
	elif event.is_action_released("fly_left"):
		target_velocity -= Vector3.LEFT

	if event.is_action_pressed("fly_right"):
		target_velocity += Vector3.RIGHT
	elif event.is_action_released("fly_right"):
		target_velocity -= Vector3.RIGHT
	
#	if event.is_action("yaw_right"):
#		r[4][0] += deg_to_rad(-1)
#		print(rad_to_deg(r[4][0]))
#	elif event.is_action("yaw_left"):
#		r[4][0] += deg_to_rad(1)
#		print(rad_to_deg(r[4][0]))

func _integrate_forces(state):
	if update_physics_parameters:
		recalculate_physics_params()
		update_physics_parameters = false
	
	# Controller
	var u = controller.compute_command(target_velocity*CTRL_SPEED)
#	print(u)
	for i in range(u.size()):
		engines[i].throttle = u[i][0] / engines[i].max_thrust
#		print(engines[i].throttle)
#		print("")
		apply_force(basis * engines[i].buildable.basis.y * engines[i].thrust, basis * engines[i].buildable.position)

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
	print("Controller Matrix K")
	print("------------------")
	for c in controller.K:
		print(c)
	print("------------------")
	print("")

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)
