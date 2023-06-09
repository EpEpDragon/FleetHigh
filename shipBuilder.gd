extends Node3D

enum {BUILD, TEST}

var state = BUILD: 
	set(value):
		state = value
		if state == BUILD:
			await get_tree().physics_frame
			ship.freeze = true
			ship.position = Vector3(0,100,0)
			ship.rotation = Vector3.ZERO
			
			ship.refuel.emit()
			ship.current_fuel = ship.max_fuel
		else:
			ship.freeze = false
		state_change = true

var current_component_type = ComponentDefs.Hull
var component_to_build : Buildable
var weld_normal := Vector3.ZERO
var state_change = false

var place_ray_query := PhysicsRayQueryParameters3D.new()
var place_internal_ray_query := PhysicsRayQueryParameters3D.new()
var remove_ray_query := PhysicsRayQueryParameters3D.new()

var is_place_component := false
var is_remove_component := false

@onready var ship : Ship = $Ship
@onready var camera :Camera3D = $Camera3D


func _ready():
	# Setup raycast queries for placing and removing
	place_ray_query.collide_with_areas = true
	place_ray_query.collide_with_bodies = false
	place_ray_query.collision_mask = 0b10
	
	place_internal_ray_query.collide_with_areas = true
	place_internal_ray_query.collide_with_bodies = false
	place_internal_ray_query.collision_mask = 0b100
	
	preview_component(current_component_type)


func _unhandled_input(event):
	if event.is_action_pressed('place_component'):
		place_component()
	elif event.is_action_pressed('remove_component'):
		is_remove_component = true
	elif event.is_action_pressed('selectengine'):
		if current_component_type == ComponentDefs.Thruster:
			current_component_type = ComponentDefs.ThrusterLarge
		else:
			current_component_type = ComponentDefs.Thruster
		preview_component(current_component_type)
	elif event.is_action_pressed('selecthull'):
		if current_component_type == ComponentDefs.HullLarge:
			current_component_type = ComponentDefs.Hull
		else:
			current_component_type = ComponentDefs.HullLarge
		preview_component(current_component_type)
	elif event.is_action_pressed('select_fuel_tank'):
		current_component_type = ComponentDefs.FuelTank
		preview_component(current_component_type)
	elif event.is_action_pressed('rotate_component_up'):
		component_to_build.rotate(weld_normal, deg_to_rad(45))
	elif event.is_action_pressed('rotate_component_down'):
		component_to_build.rotate(weld_normal, deg_to_rad(-45))
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_R:
		if state == BUILD:
			state = TEST
		else:
			state = BUILD

var previous_position : Vector3
func _physics_process(delta):
	if ship:
		$MeshInstance3D.position = ship.basis * ship.center_of_mass  + ship.position
		
		# Place/Remove component
	#	if state == BUILD:
		var result : Dictionary
		if component_to_build.internal:
			result = mouse_ray_query(place_internal_ray_query)
		else:
			result = mouse_ray_query(place_ray_query)
		if result:
			if result.normal != weld_normal:
				weld_normal = result.normal
				component_to_build.rotation = Vector3.ZERO
			
			# TODO add file to contain all types
			if component_to_build.internal:
				component_to_build.position = result.collider.buildable.position
			else:
				component_to_build.position = weld_normal * ((result.collider.get_parent().buildable.size + component_to_build.size) / 2) + result.collider.get_parent().buildable.position
			# If component moves in space reset its blocked state
			if not previous_position.is_equal_approx(component_to_build.position):
				component_to_build.blocked = false
				previous_position = component_to_build.position
			component_to_build.check_connections()
			component_to_build.visible = true
		else:
			component_to_build.position = Vector3(10000,10000,10000) # Move away
			component_to_build.blocked = false
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
	component_to_build.position = Vector3(10000,10000,10000) # Move away
	ship.add_child(component_to_build)


func place_component():
	component_to_build.check_connections()
	if component_to_build.can_weld:
		component_to_build.preview = false
		component_to_build = null
		# Preview next component
		preview_component(current_component_type)


func remove_component(shape_id):
	ship.shape_owner_get_owner(ship.shape_find_owner(shape_id)).queue_free()


func mouse_ray_query(query):
	var space_state := get_world_3d().direct_space_state
	query.from = camera.position
	query.to = query.from + camera.project_ray_normal(get_viewport().get_mouse_position())*100
	return space_state.intersect_ray(query)
