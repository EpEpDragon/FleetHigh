extends Resource
## Class used to load/save ship components
class_name ComponentData

@export var type := 0
@export var health := 0
@export var position := Vector3.ZERO
@export var rotation := Vector3.ZERO
@export var welds_data : Array[int]
@export var key : int

## Initialises and adds component to ship
#func init_component(ship : Ship):
#	match type:
#		ComponentDefs.Type.HULL : component_instance = ComponentDefs.Hull.instantiate()
#		ComponentDefs.Type.THRUSTER : component_instance = ComponentDefs.Thruster.instantiate()
#	ship.add_child(component_instance)
#	component_instance.preview = false

## Set up component connections
func connect_component(ship_ref : Ship, my_key : int):
	for i in welds_data.size():
		if welds_data[i] != -1:
			ship_ref.components[my_key].weld_points[i].connection = ship_ref.components[welds_data[i]]
