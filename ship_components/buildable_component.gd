extends CollisionShape3D
class_name Buildable

@export var mass := 0.0 # tonne
@export var inertia := Vector3.ZERO # tonne m^2

var weld_points : Array[WeldPoint]
var thrust_component : ThrustComponent

var preview := true:
	set(value):
		preview = value
		if not preview:
#			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
#			material.albedo_color = Color.WHITE
			for wp in weld_points:
				wp.collision_layer = 0xFFFF
			if thrust_component:
				thrust_component.add_thruster()
			ship.components.append(self)
			ship.update_physics_parameters = true
			disabled = false

@onready var ship : Ship = get_parent()
@onready var material : StandardMaterial3D = $MeshInstance3D.mesh.surface_get_material(0)


func _ready():
	disabled = true
	for wp in weld_points:
		wp.collision_layer = 0x0000


func _exit_tree():
	ship.components.erase(self)
	ship.update_physics_parameters = true
