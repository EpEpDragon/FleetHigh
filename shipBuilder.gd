extends Node3D

const ShipComponent := preload("res://Nodes/ShipComponenet.tscn")
const ShipEngine := preload("res://Nodes/ShipEngine.tscn")

enum {BUILD, TEST}

var state = BUILD: 
	set(value):
		state = value
		state_change = true

var component_to_build = ShipComponent
var state_change = false

var place_ray_query := PhysicsRayQueryParameters3D.new()
var remove_ray_query := PhysicsRayQueryParameters3D.new()

var is_place_component := false
var is_remove_component := false

@onready var ship := $Ship
@onready var camera := $Camera3D
@onready var space_state := get_world_3d().direct_space_state

# Called when the node enters the scene tree for the first time.
func _ready():
	place_ray_query.collide_with_areas = true
	place_ray_query.collide_with_bodies = false


func _input(event):
	if event.is_action_pressed('place_component'):
		is_place_component = true
	elif event.is_action_pressed('remove_component'):
		is_remove_component = true
	elif event.is_action_pressed('selectengine'):
		component_to_build = ShipEngine
	elif event.is_action_pressed('selecthull'):
		component_to_build = ShipComponent
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_R:
		if state == BUILD:
			state = TEST
		else:
			state = BUILD
			


func _physics_process(delta):
	if state_change:
		if state == BUILD:
			pass
			ship.freeze = true
			ship.position = Vector3(0,100,0)
			ship.rotation = Vector3.ZERO
		elif state == TEST:
			ship.freeze = false
	
	if is_place_component:
		var result = click_query(place_ray_query)
		if result:
			place_component(result.collider.to_global(result.collider.weld_position))
		is_place_component = false
	elif is_remove_component:
		var result = click_query(remove_ray_query)
		if result:
			remove_component(result.shape)
		is_remove_component = false
		

func place_component(_position):
	var component = component_to_build.instantiate()
	ship.add_child(component)
	component.global_position = _position

func remove_component(shape_id):
	var owner = ship.shape_find_owner(shape_id)
	print("Before remove")
	print("ShapeID: " + str(shape_id))
	print("ShapeOwner: " + str(ship.shape_find_owner(shape_id)))
	print(ship.get_shape_owners())
#	ship.remove_shape_owner(owner)
	ship.remove_child(ship.shape_owner_get_owner(owner))


func click_query(query):
	query.from = camera.position
	query.to = query.from + camera.project_ray_normal(get_viewport().get_mouse_position())*100
	return space_state.intersect_ray(query)
