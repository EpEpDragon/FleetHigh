extends Resource
## Class used to save/load ships
class_name ShipData

@export var name := "Ship"
# TODO Component array to use dictionary
@export var components : Dictionary

## Initialise ship from saved data
func init_ship(ship : Ship):
	# First initialise all components
	var component_instance : Buildable
	for c in components:
		match components[c].type:
			# FIXME why does preload  not work here??
			ComponentDefs.Type.HULL:
#				component_instance = ComponentDefs.Hull.instantiate()
				component_instance = load("res://ship_components/hull/ShipComponenet.tscn").instantiate()
			ComponentDefs.Type.THRUSTER:
#				component_instance = ComponentDefs.Thruster.instantiate()
				component_instance = load("res://ship_components/engine/ShipEngine.tscn").instantiate()
		component_instance.component_data = components[c]
		component_instance.position = components[c].position
		component_instance.rotation = components[c].rotation
		ship.add_child(component_instance)
		component_instance.preview = false
	# Then connect required components
	for key in components:
		components[key].connect_component(ship, key)
