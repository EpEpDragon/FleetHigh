extends CollisionShape3D

## Base class for anything that can be placed on a ship.
class_name Buildable

## Used for component saving/loading
var component_data : ComponentData

## Possible buildable types
enum Type {HULL, THRUSTER}

## Type of the buildable
@export var type := Type.HULL

## Mass of the buildable.
@export var mass := 0.0 # tonne

## Inertia of the buildable.
@export var inertia := Vector3.ZERO # tonne m^2

## Array containing all weld points of this buildable.
var weld_points : Array[WeldPoint]

## Thrust component of this buildable
var thrust_component : ThrustComponent

## True when any of the weld points are valid for connection.
var can_weld := false

## True when any of the weld points are not valid for connection.
var blocked := false

## True if this buildable is currently being previewed in build mode.
var preview := true:
	set(value):
		preview = value
		if not preview:
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color = Color.WHITE
			for wp in weld_points:
				wp.collision_layer = 0b10
				wp.weld_area.monitoring = false
			if thrust_component:
				thrust_component.add_thruster()
			ship.components.append(self)
			
			# Create component data if it does not exist (i.e not being loaded from save)
			if not component_data:
				component_data = ComponentData.new()
				component_data.type = type
				component_data.position = position
				ship.ship_data.components.append(component_data)
			
			ship.update_physics_parameters = true
			disabled = false

## Contains reference to the parent ship of this buildable.
@onready var ship : Ship = get_parent()

## Contains reference to the material used in this buildable.
@onready var material : StandardMaterial3D = $MeshInstance3D.mesh.surface_get_material(0)


func _ready():
	disabled = true
	for wp in weld_points:
		wp.collision_layer = 0b0


func _exit_tree():
	ship.components.erase(self)
	ship.update_physics_parameters = true


## Checks if this buildable can be placed, used while previewing in build mode.
func check_connections():
	if not blocked:
		for wp in weld_points:
	#		wp.try_weld()
			if wp.connection != null:
				material.albedo_color = Color(0,1,0,0.5)
				can_weld = true
				return
	can_weld = false
	material.albedo_color = Color(1,0,0,0.5)
