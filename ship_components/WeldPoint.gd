extends Area3D
## Used to weld buildables together.
class_name WeldPoint

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
	buildable.weld_points.append(self)


func _on_weld_area_area_entered(area):
	if buildable.preview:
		if area.get_parent().connection == null:
			connection = area.get_parent().buildable
			area.get_parent().connection = buildable
		else:
			buildable.blocked = true


func _on_weld_area_area_exited(area):
	var to = area.get_parent().connection
	if buildable.preview:
		if to == buildable:
			print("pass")
			connection = null
			area.get_parent().connection = null
