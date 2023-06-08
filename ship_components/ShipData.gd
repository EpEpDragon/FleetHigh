extends Resource
## Class used to save/load ships
class_name ShipData

@export var name := "Ship"
@export var components : Array[ComponentData]

## Initialise ship from saved data
func init_ship(ship : Ship):
	# First initialise all components
	var component_instance : Buildable
	for c in components:
		match c.type:
			# FIXME why does preload  not work here??
			ComponentDefs.Type.HULL:
#				component_instance = ComponentDefs.Hull.instantiate()
				component_instance = load("res://ship_components/hull/ShipComponenet.tscn").instantiate()
			ComponentDefs.Type.THRUSTER:
#				component_instance = ComponentDefs.Thruster.instantiate()
				component_instance = load("res://ship_components/engine/ShipEngine.tscn").instantiate()
		ship.add_child(component_instance)
		component_instance.component_data = c
		component_instance.position = c.position
		component_instance.preview = false
	# Then connect required components
	for i in components.size():
		components[i].connect_component(ship, i)
