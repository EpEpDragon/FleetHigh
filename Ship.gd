extends RigidBody3D
class_name Ship

const CTRL_ACCELERATION = 15.0

var ShipEngine := preload("res://ship_components/ShipEngine.gd")

var engines : Array[ThrustComponent]
var peak_directional_thrust := {"positive" = Vector3.ZERO,
								"negative" = Vector3.ZERO}

var update_physics_parameters := false
var target_acceleration := Vector3.ZERO

func _ready():
#	pass
	get_child(0).preview = false

func _input(event):
	if event.is_action_pressed("fly_up"):
		target_acceleration = Vector3.UP * CTRL_ACCELERATION
	elif event.is_action_released("fly_up"):
		target_acceleration = Vector3.ZERO
	if event.is_action_pressed("fly_down"):
		target_acceleration = Vector3.DOWN * CTRL_ACCELERATION
	elif event.is_action_released("fly_down"):
		target_acceleration = Vector3.ZERO

func _integrate_forces(state):
	if update_physics_parameters:
		recalculate_physics_params()
		update_physics_parameters = false
	
	# TODO Clean up force calculations
	# Apply engine thrust
	var force = mass * (-state.total_gravity + target_acceleration) * basis # Force to apply on ship body, in ship coordinates
	for e in engines:
		if e.active:
			var force_frac = force.length() / (force.normalized().dot(e.thrust_vector)) # Maximum force fraction that this engie can contribute
			var relative_frac = abs(force.normalized().dot(e.linear_thrust_fraction)) # Fraction that this engine should contribute relative to other engines
			e.throttle = clamp(force_frac*relative_frac, 0, 1)
			print(e.throttle)
			apply_force(basis * e.buildable.basis.y * e.thrust * e.throttle, basis * e.buildable.position)


func recalculate_physics_params():
	var M = 0
	var CM = Vector3.ZERO
	var I = Vector3.ZERO
	for c in get_children():
		if not c.preview:
			M += c.mass
	for c in get_children():
		if not c.preview:
			CM += (c.mass * c.position)/M
	for c in get_children():
		if not c.preview:
			var origin = CM-c.position
			I += c.inertia + c.mass * (Vector3.ONE * origin.dot(origin) - vec_sqr(origin))
	mass = M
	center_of_mass = CM
	inertia = I

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)
