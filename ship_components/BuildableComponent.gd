extends CollisionShape3D
## Base class for anything that can be placed on a ship.
class_name Buildable

## Hash key to this component
var key : int

## Flag to indicate that this componen tis being loaded from a save
var loading := true

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

# TODO Make this logic in a signal or something
## True if this buildable is currently being previewed in build mode.
var preview := true:
	set(value):
		preview = value
		if not preview:
			# TODO Make this not break when preview is set to false before add_child()
#			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color = Color(1,1,1,0.5)
			for wp in weld_points:
				wp.collision_layer = 0b10
				wp.weld_area.monitoring = false
			if thrust_component:
				thrust_component.add_thruster()
			
			if loading:
				key = component_data.key
				ship.next_key = max(key + 1, ship.next_key)
			else:
				key = ship.next_key
				ship.next_key += 1
				component_data.key = key
			ship.components[key] = self
			
			# Create component data if it does not exist (i.e not being loaded from save)

			component_data.position = position
			component_data.rotation = rotation
#				for wp in weld_points:
#					component_data.welds_data.append(wp.weld_data)
#					component_data.welds_data.append(wp.connection_idx)
			ship.ship_data.components[key] = component_data
			
			ship.update_physics_parameters = true
			disabled = false
#			print("--------")
#			for c in ship.components:
#				print(str(ship.components[c].key)+ ": "+ str(ship.components[c].component_data.welds_data))
#			print("--------")
			
			# Physics parameters
			add_mass()


## Contains reference to the parent ship of this buildable.
@onready var ship : Ship = get_parent()

## Contains reference to the material used in this buildable.
@onready var material : StandardMaterial3D = $MeshInstance3D.mesh.surface_get_material(0)

func add_mass():
	ship.M += mass
	var relative = position - ship.center_of_mass
	var CM_change = (mass * (relative))/ship.mass
	
	ship.center_of_mass += CM_change
	
	ship.inertia = ship.inertia + (ship.mass-mass) * (Vector3.ONE * CM_change.length_squared() - vec_sqr(CM_change))
	relative = position - ship.center_of_mass
	ship.inertia += inertia + mass * (Vector3.ONE * relative.length_squared() - vec_sqr(relative))

func remove_mass():
	ship.M -= mass
	var relative = position - ship.center_of_mass
	var CM_change = -(mass * (relative))/ship.mass
	
	ship.center_of_mass += CM_change
	
	ship.inertia = ship.inertia + (ship.mass+mass) * (Vector3.ONE * CM_change.length_squared() - vec_sqr(CM_change))
	relative = position - ship.center_of_mass
	var diff = inertia + mass * (Vector3.ONE * relative.length_squared() - vec_sqr(relative))
	
	# Check for floating point errors that make inertia < 0
	if diff.x > ship.inertia.x || diff.y > ship.inertia.y || diff.z > ship.inertia.z:
		ship.inertia = Vector3.ZERO
	else:
		ship.inertia -= diff

func vec_sqr(vector:Vector3) -> Vector3:
	return Vector3(vector.x*vector.x, vector.y*vector.y, vector.z*vector.z)

func _ready():
	disabled = true
	for wp in weld_points:
		wp.collision_layer = 0b0
	
	# Initialise component data if none exists (not loading ship)
	if not component_data:
		loading = false
		component_data = ComponentData.new()
		component_data.type = type
		component_data.welds_data.resize(weld_points.size())
		component_data.welds_data.fill(-1)


func _exit_tree():
	if !preview:
		for connected_key in component_data.welds_data:
			if connected_key != -1:
				for i in ship.components[connected_key].component_data.welds_data.size():
					if ship.components[connected_key].component_data.welds_data[i] == key:
						ship.components[connected_key].component_data.welds_data[i] = -1
		ship.components.erase(key)
		ship.ship_data.components.erase(key)
		ship.update_physics_parameters = true
#		print("--------")
#		for c in ship.components:
#			print(str(ship.components[c].key)+ ": "+ str(ship.components[c].component_data.welds_data))
#		print("--------")

		remove_mass()
		
		# Used for save loading of new ship
#		if ship.components.is_empty():
#			ship.ship_cleared


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
