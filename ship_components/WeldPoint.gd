extends Area3D
class_name WeldPoint
@export var weld_position = Vector3(4,0,0)

@onready var buildable : Buildable = get_parent()

func _ready():
	buildable.weld_points.append(self)
