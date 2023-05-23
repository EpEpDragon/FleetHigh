extends CollisionShape3D

@onready var ship := get_parent()
@onready var particles := $GPUParticles3D
@onready var base_lifetime = particles.lifetime
var thrust = 10_000 # N

var id : int

var active = false:
	set(value):
		active = value
		particles.emitting = value

var throttle := 0.0:
	set(value):
		throttle = value
		particles.lifetime = value * base_lifetime

func _ready():
	ship.engines.append(self)
	id = ship.engines.size()-1

func _exit_tree():
	ship.engines.erase(self)
