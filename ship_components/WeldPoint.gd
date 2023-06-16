extends Area3D
## Used to weld buildables together.
class_name WeldPoint

## Index of this weld point in parent buildable
var index : int

## Buildable currently connected to this weld point.
var connection : Buildable = null

## Owning buildable of this weld point.
@onready var buildable : Buildable = get_parent()

## Normal vector to this weld point.
@onready var weld_normal := buildable.basis * basis.x

## Weld position offset
@onready var weld_position : Vector3 = Vector3(1,0,0) * buildable.size

func _ready():
#	weld_data = WeldData.new()
	index = buildable.weld_points.size()
	buildable.weld_points.append(self)


func _on_area_entered(area):
	if buildable.preview:
		if area.connection == null:
			# Self
			connection = area.buildable
			buildable.component_data.welds_data[index] = area.buildable.key
			# Other
			area.connection = buildable
			area.buildable.component_data.welds_data[area.index] = buildable.ship.next_key
		else:
			buildable.blocked = true


func _on_area_exited(area):
	var to = area.connection
	if buildable.preview:
		if to == buildable:
			# Self
			connection = null
			buildable.component_data.welds_data[index] = -1
			# Other
			area.connection = null
			area.buildable.component_data.welds_data[area.index] = -1
