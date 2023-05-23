extends Node3D
class_name ThrustComponent

@export var thrust = 0.0 # kN

var active := true:
	set(value):
		active = value
		particles.emitting = value
var throttle := 0.0:
	set(value):
		throttle = value
		if throttle < 0.05:
			active = false
		else:
			active = true
			particles.lifetime = value * value * base_lifetime
var linear_thrust_fraction := Vector3.ZERO

@onready var buildable : Buildable = get_parent()
@onready var ship : Ship = buildable.get_parent()
@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var base_lifetime := particles.lifetime

@onready var thrust_position := buildable.position

func _ready():
	ship.engines.append(self)
	ship.static_thrust_vector += buildable.basis * Vector3.UP * thrust
	update_thruster_fractions()


func _exit_tree():
	ship.engines.erase(self)
	ship.static_thrust_vector -= buildable.basis * Vector3.UP * thrust
	update_thruster_fractions()


func update_thruster_fractions():
	for e in ship.engines:
		e.linear_thrust_fraction = (e.buildable.basis * Vector3.UP * thrust) / ship.static_thrust_vector
		# TODO Make nan check not necessary
		if is_nan(e.linear_thrust_fraction.x) : e.linear_thrust_fraction.x = 0
		if is_nan(e.linear_thrust_fraction.y) : e.linear_thrust_fraction.y = 0
		if is_nan(e.linear_thrust_fraction.z) : e.linear_thrust_fraction.z = 0
		print(str(e) + " thrust fraction: " + str(e.linear_thrust_fraction))
