extends RigidBody3D
var ShipEngine := preload("res://Nodes/ShipEngine.gd")

var engines:Array
var engine_forces:Array

var update_physics_parameters := false
func _input(event):
	if event.is_action_pressed("fly_up"):
		for e in engines:
			e.active = true
	elif event.is_action_released("fly_up"):
		for e in engines:
			e.active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)

func _integrate_forces(state):
#	print("Tensor: " + str(get_inverse_inertia_tensor().inverse()) + "kg m^2")
#	print("Principal : " + str(state.principal_inertia_axes))

	if update_physics_parameters:
		# Recalculate mass, center mass and rotational inertia
		var M = 0
		var CM = Vector3.ZERO
		var I = Vector3.ZERO
		for c in get_children():
			M += c.mass
		for c in get_children():
			CM += (c.mass * c.position)/M
		for c in get_children():
			var origin = CM-c.position
			I += c.inertia + c.mass * (Vector3.ONE * origin.dot(origin) - vec_sqr(origin))
		mass = M
		center_of_mass = CM
		inertia = I
#		print("Position: " + str(c.position))
#		print("Mass: " + str(mass))
#		print("CM: " + str(center_of_mass) + "m")
#		print("RI: " + str(inertia) + "kg m^2")
#		print("Tensor: " + str(get_inverse_inertia_tensor()) + "kg m^2")
#		print("")
		update_physics_parameters = false
	
	# Apply engine thrust
	for e in engines:
		if e.active:
			apply_force(basis * e.buildable.basis.y * e.thrust, basis * e.buildable.position)

