extends Node3D
class_name Buildable

@export var mass := 0.0 # tonne
@export var inertia := Vector3.ZERO # tonne m^2

@onready var ship:RigidBody3D = get_parent()

func _ready():
	ship.update_physics_parameters = true
