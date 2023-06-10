extends RigidBody3D
class_name Ship

signal ship_cleared

@export var speed = 300
@export var controller : Controller
@export var camera : Camera3D
var aim_direction

var ship_data : ShipData
var components : Dictionary
var engines : Array[ThrustComponent]
var next_key : int = 0

var M = 0:
	set(value):
		M = value
		if M <= 0:
			mass = 0.0001
		else:
			mass = M

var peak_directional_thrust := {"positive" = Vector3.ZERO,
								"negative" = Vector3.ZERO}

var update_physics_parameters := false#:
#	set(value):
#		update_physics_parameters = value
#		if update_physics_parameters == true:
#			await get_tree().physics_frame
#			recalculate_physics_params()
#			update_physics_parameters = false

var target_velocity := Vector3.ZERO

func _ready():
	if not ship_data:
		ship_data = ShipData.new()
#	get_child(2).preview = false
	
#func _unhandled_input(event):
#	if event is InputEventMouseMotion:
#		camera.basis.z
		
func _unhandled_key_input(event):
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

var prev_vel := Vector3.ZERO
func _physics_process(delta):
	var delta_v = abs(linear_velocity - prev_vel)
	print(max(delta_v.x, delta_v.y, delta_v.z)/(delta*9.81))
#	print(linear_velocity)
	prev_vel = linear_velocity
	

func _integrate_forces(state):
	if update_physics_parameters:
		controller.solve_K()
		print("Controller Matrix K")
		print("------------------")
		for c in controller.K:
			print(c)
		print("------------------")
		print("")
		update_physics_parameters = false
	
	# Controller
	var ang = acos(Vector2(camera.basis.z.x, camera.basis.z.z).normalized().dot(Vector2.DOWN))
	if camera.basis.z.x < 0:
		ang = -ang
	var u = controller.compute_command(target_velocity.rotated(Vector3.UP, ang) * speed, 0)
	for i in range(u.size()):
		engines[i].throttle = u[i][0] / engines[i].max_thrust
		apply_force(basis * engines[i].buildable.basis.y * engines[i].thrust, basis * engines[i].buildable.position)


#func recalculate_physics_params():
#	var M = 0
#	var CM = Vector3.ZERO
#	var I = Vector3.ZERO
#	for c in components:
#		if not components[c].preview:
#			M += components[c].mass
#	for c in components:
#		if not components[c].preview:
#			CM += (components[c].mass * components[c].position)/M
#	for c in components:
#		if not components[c].preview:
#			var origin = CM-components[c].position
#			I += components[c].inertia + components[c].mass * (Vector3.ONE * origin.dot(origin) - vec_sqr(origin))
#
#	# FIXME Bug?, need to freez before setting mass and inertia to prevent incorrect acceleration.-
##	freeze = true
#	mass = M
#	center_of_mass = CM
#	inertia = I
##	freeze = false
#
#	controller.solve_K()
#	print("Controller Matrix K")
#	print("------------------")
#	for c in controller.K:
#		print(c)
#	print("------------------")
#	print("")
#

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)
