extends Node3D

const ShipComponent := preload("res://ship_components/ShipComponenet.tscn")
const ShipEngine := preload("res://ship_components/ShipEngine.tscn")

enum {BUILD, TEST}

var state = BUILD: 
	set(value):
		state = value
		state_change = true

var current_component_type = ShipComponent
var component_to_build : Buildable
var weld_normal := Vector3.ZERO
var state_change = false

var place_ray_query := PhysicsRayQueryParameters3D.new()
var remove_ray_query := PhysicsRayQueryParameters3D.new()

var is_place_component := false
var is_remove_component := false

@onready var ship := $Ship
@onready var camera := $Camera3D
@onready var space_state := get_world_3d().direct_space_state



func _ready():
	# Setup raycast queries for placing and removing
	place_ray_query.collide_with_areas = true
	place_ray_query.collide_with_bodies = false
	preview_component(current_component_type)


func _input(event):
	if event.is_action_pressed('place_component'):
		component_to_build.preview = false
		component_to_build = null
		preview_component(current_component_type)
	elif event.is_action_pressed('remove_component'):
		is_remove_component = true
	elif event.is_action_pressed('selectengine'):
		current_component_type = ShipEngine
		preview_component(ShipEngine)
	elif event.is_action_pressed('selecthull'):
		current_component_type = ShipComponent
		preview_component(ShipComponent)
	elif event.is_action_pressed('rotate_component_up'):
		component_to_build.rotate(weld_normal, deg_to_rad(45))
	elif event.is_action_pressed('rotate_component_down'):
		component_to_build.rotate(weld_normal, deg_to_rad(-45))
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_R:
		if state == BUILD:
			state = TEST
		else:
			state = BUILD


func _physics_process(delta):
	$MeshInstance3D.position = ship.basis * ship.center_of_mass  + ship.position
	if state_change:
		# States for physics frozen and unfrozen
		if state == BUILD:
			ship.freeze = true
			ship.position = Vector3(0,100,0)
			ship.rotation = Vector3.ZERO
		elif state == TEST:
			ship.freeze = false
	
	# Place/Remove component
#	if state == BUILD:
	var result = mouse_ray_query(place_ray_query)
	if result:
		if result.collider.weld_normal != weld_normal:
			weld_normal = result.collider.weld_normal
			component_to_build.rotation = Vector3.ZERO
		component_to_build.position = result.collider.basis * result.collider.weld_position + result.collider.buildable.position
		component_to_build.visible = true
	else:
		component_to_build.visible = false
		component_to_build.rotation = Vector3.ZERO
	if is_remove_component:
		result = mouse_ray_query(remove_ray_query)
		if result:
			remove_component(result.shape)
		is_remove_component = false


func preview_component(component):
	if component_to_build:
		component_to_build.queue_free()
	component_to_build = component.instantiate()
	component_to_build.visible = false
	ship.add_child(component_to_build)


func place_component():
	component_to_build.preview = false


func remove_component(shape_id):
	ship.shape_owner_get_owner(ship.shape_find_owner(shape_id)).queue_free()


func mouse_ray_query(query):
	query.from = camera.position
	query.to = query.from + camera.project_ray_normal(get_viewport().get_mouse_position())*100
	return space_state.intersect_ray(query)
