extends RigidBody3D
var ShipEngine := preload("res://Nodes/ShipEngine.gd")

var engines:Array
var engine_forces:Array

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

func _integrate_forces(state):
	for e in engines:
		if e.active:
			apply_force(basis * e.basis.y * e.thrust, basis * e.position)

