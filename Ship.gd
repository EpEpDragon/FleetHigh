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
	var force : Vector3 = mass * (-state.total_gravity + target_acceleration) * basis # Force to apply on ship body, in ship coordinates
	var total_thrust = 0
	var i = 0
	for e in engines:
		if e.active:
			# Inverse maximum force fraction that this engie can contribute
#			var inv_force_fraction = clamp(force.length() / (force.normalized().dot(e.thrust_vector)),0,INF)
			
			# Fraction that this engine should be normalized by relative to other engines
#			var axis_normalized_force = abs(force/force[abs(force).max_axis_index()])
#			var scaled_normalisation_fraction = abs(e.linear_thrust_fraction * axis_normalized_force)
			
			
#			e.throttle = clamp((inv_force_fraction * scaled_normalisation_fraction[scaled_normalisation_fraction.max_axis_index()]), 0, 1)
			e.throttle = clamp(force.normalized().dot(e.thrust_vector) / e.thrust, 0, 1)
			total_thrust += (e.thrust_vector.normalized()*e.throttle*e.thrust).dot(force.normalized())
			
			
		
#	var tempo = force * total_thrust.inverse()
#	if is_nan(tempo.x) or is_inf(tempo.x) :  tempo.x = 0
#	if is_nan(tempo.y) or is_inf(tempo.y) :  tempo.y = 0
#	if is_nan(tempo.z) or is_inf(tempo.z) :  tempo.z = 0
#	tempo = tempo.length()
	var temp = 0
	if total_thrust:
		temp = force.length() / total_thrust
	for e in engines:
		if e.active:
			e.throttle = clamp(e.throttle * temp,0,1)
			apply_force(basis * e.buildable.basis.y * e.thrust * e.throttle, basis * e.buildable.position)
			print(str(i) + ": " + str(e.throttle))
		i+=1

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
