extends Node3D

@onready var buildable := get_parent()
@onready var ship := buildable.get_parent()
@onready var particles := $GPUParticles3D
@onready var base_lifetime = particles.lifetime
@onready var thrust_position = buildable.position

@export var thrust = 0.0 # kN


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

func _exit_tree():
	ship.engines.erase(self)
