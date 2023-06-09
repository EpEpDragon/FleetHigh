extends Area3D
## Used to weld buildables together.
class_name WeldPoint

## Index of this weld point in parent buildable
var index : int

## Weld position offset
@export var weld_position = Vector3(4,0,0)

## Buildable currently connected to this weld point.
var connection : Buildable = null

## Owning buildable of this weld point.
@onready var buildable : Buildable = get_parent()

## Normal vector to this weld point.
@onready var weld_normal := buildable.basis * basis.x

## Area3D used for checking valid welds.
@onready var weld_area : Area3D = $WeldArea

func _ready():
#	weld_data = WeldData.new()
	index = buildable.weld_points.size()
	buildable.weld_points.append(self)
	
# Set up connection
func _on_weld_area_area_entered(area):
	if buildable.preview:
		if area.get_parent().connection == null:
			# Self
			connection = area.get_parent().buildable
			buildable.component_data.welds_data[index] = area.get_parent().buildable.key
			# Other
			area.get_parent().connection = buildable
			area.get_parent().buildable.component_data.welds_data[area.get_parent().index] = buildable.ship.next_key
		else:
			buildable.blocked = true

# Remove connection
func _on_weld_area_area_exited(area):
	var to = area.get_parent().connection
	if buildable.preview:
		if to == buildable:
			# Self
			connection = null
			buildable.component_data.welds_data[index] = -1
			# Other
			area.get_parent().connection = null
			area.get_parent().buildable.component_data.welds_data[area.get_parent().index] = -1
