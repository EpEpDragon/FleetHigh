extends RigidBody3D
class_name Ship

signal ship_cleared
signal use_fuel
signal refuel

@export var speed = 300
@export var controller : Controller
@export var camera : Camera3D
@export var gui : ShipGUI
var aim_direction

var ship_data : ShipData
var components : Dictionary
var engines : Array[ThrustComponent]
var wet_fuel_tanks : int:
	set(value):
		wet_fuel_tanks = clamp(value,0,INF)
var max_fuel : float:
	set(value):
		max_fuel = value
		gui.fuel_bar.max_value = max_fuel
		gui.fuel_label.text = str(int(current_fuel)) + " L / " + str(max_fuel) + " L"
var current_fuel : float:
	set(value):
		current_fuel = clamp(value, 0, max_fuel)
		gui.fuel_bar.value = current_fuel
		gui.fuel_label.text = str(int(current_fuel)) + " L / " + str(max_fuel) + " L"
var next_key : int = 0
var engines_on := true:
	set(value):
		engines_on = value
		for e in engines:
			e.throttle = 0

var M = 0:
	set(value):
		M = value
		if M <= 0:
			mass = 0.0001
		else:
			mass = M

var peak_directional_thrust := {"positive" = Vector3.ZERO,
								"negative" = Vector3.ZERO}

var update_physics_parameters := false

var target_velocity := Vector3.ZERO

func _ready():
	# Required rotation order, lest shit hits the fan...
	# TODO Maybe use quaternions? To prevent above...
	rotation_order = EULER_ORDER_XZY
	if not ship_data:
		ship_data = ShipData.new()
#	get_child(2).preview = false


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
	
	if event.is_action_pressed("toggle_engines_on"):
		engines_on = !engines_on


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
	# TODO Move some of this into engine components?
	if engines_on:
		var ang = acos(Vector2(camera.basis.z.x, camera.basis.z.z).normalized().dot(Vector2.DOWN))
		if camera.basis.z.x < 0:
			ang = -ang
		var u = controller.compute_command(target_velocity.rotated(Vector3.UP, ang) * speed, ang)
		for i in range(u.size()):
			if wet_fuel_tanks > 0:
				engines[i].throttle = u[i][0] / engines[i].max_thrust
				apply_force(basis * engines[i].buildable.basis.y * engines[i].thrust, basis * engines[i].buildable.position)
				use_fuel.emit((engines[i].thrust * engines[i].fuel_usage * get_process_delta_time()) / wet_fuel_tanks)
			else:
				engines[i].throttle = 0
#			print((engines[i].thrust * engines[i].fuel_usage*get_process_delta_time()) / wet_fuel_tanks)
	#		print(engines[i].thrust)

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)
