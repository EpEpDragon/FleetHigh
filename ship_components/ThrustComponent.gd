extends Node3D
class_name ThrustComponent

@export var max_thrust = 0.0 # kN

var thrust = 0.0 # kN
var active := true:
	set(value):
		active = value
		particles.emitting = value
var throttle := 0.0:
	set(value):
		throttle = clamp(value,0,1)
		thrust = throttle * max_thrust


var linear_thrust_fraction := Vector3.ZERO


@onready var buildable : Buildable = get_parent()
@onready var ship : Ship = buildable.get_parent()
@onready var thrust_vector : Vector3
@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var base_lifetime := particles.lifetime


func _ready():
	buildable.thrust_component = self


func _process(delta):
#	thrust += (throttle * max_thrust - thrust)*20*delta
	if thrust / max_thrust < 0.05:
		particles.emitting = false
	else:
		particles.lifetime = (thrust / max_thrust) * base_lifetime
		particles.emitting = true


func _exit_tree():
	if not buildable.preview:
		ship.engines.erase(self)
		ship.peak_directional_thrust.positive -= thrust_vector.clamp(Vector3.ZERO,Vector3.INF)
		ship.peak_directional_thrust.negative -= -thrust_vector.clamp(-Vector3.INF,Vector3.ZERO)
		update_thruster_fractions()


func add_thruster():
	thrust_vector = buildable.basis * Vector3.UP * max_thrust
	# Fix float errors
	if is_zero_approx(thrust_vector.x): thrust_vector.x = 0
	if is_zero_approx(thrust_vector.y): thrust_vector.y = 0
	if is_zero_approx(thrust_vector.z): thrust_vector.z = 0
	ship.engines.append(self)
	ship.peak_directional_thrust.positive += thrust_vector.clamp(Vector3.ZERO,Vector3.INF)
	ship.peak_directional_thrust.negative += -thrust_vector.clamp(-Vector3.INF,Vector3.ZERO)
	update_thruster_fractions()


func update_thruster_fractions():
#	var i = 0
	for e in ship.engines:
		if e.thrust_vector.x > 0:
			e.linear_thrust_fraction.x = e.thrust_vector.x / ship.peak_directional_thrust.positive.x
		elif e.thrust_vector.x < 0:
			e.linear_thrust_fraction.x = e.thrust_vector.x / ship.peak_directional_thrust.negative.x
			
		if e.thrust_vector.y > 0:
			e.linear_thrust_fraction.y = e.thrust_vector.y / ship.peak_directional_thrust.positive.y
		elif e.thrust_vector.y < 0:
			e.linear_thrust_fraction.y = e.thrust_vector.y / ship.peak_directional_thrust.negative.y
			
		if e.thrust_vector.z > 0:
			e.linear_thrust_fraction.z = e.thrust_vector.z / ship.peak_directional_thrust.positive.z
		elif e.thrust_vector.z < 0:
			e.linear_thrust_fraction.z = e.thrust_vector.z / ship.peak_directional_thrust.negative.z
