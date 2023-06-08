extends Resource
## Class used to load/save ship components
class_name ComponentData

@export var type := 0
@export var health := 0
@export var connections := []
@export var position := Vector3.ZERO
@export var rotation := Vector3.ZERO

## Initialises and adds component to ship
#func init_component(ship : Ship):
#	match type:
#		ComponentDefs.Type.HULL : component_instance = ComponentDefs.Hull.instantiate()
#		ComponentDefs.Type.THRUSTER : component_instance = ComponentDefs.Thruster.instantiate()
#	ship.add_child(component_instance)
#	component_instance.preview = false

## Set up component connections
func connect_component(ship_ref : Ship, buildable_id : int):
	for i in range(connections.size()):
		ship_ref.components[buildable_id].weld_points[i].connection = ship_ref.components[connections[i]]
