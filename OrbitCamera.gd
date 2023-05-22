extends Camera3D
enum {REST, ORBIT, PAN}

const SENSITIVITY = 0.001

var state := REST
var orbit_point : Vector3 # Global space
var update_orbit := false
var separation := 20.0

#var rotate_arm := Vector3.ZERO
#var rotate_angle := 0.0

var ray_query := PhysicsRayQueryParameters3D.new()
@onready var space_state := get_world_3d().direct_space_state
@onready var orbit_point_visual := $OrbitPointVisual

func _ready():
	orbit_point_visual.visible = false


func _input(event):
	if event.is_action_pressed("orbit"):
		state = ORBIT
		update_orbit = true
		print("orbit")
	elif event.is_action_released("orbit"):
		state = REST
		orbit_point_visual.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("rest")
	
	if state == ORBIT:
		if event is InputEventMouseMotion:
			var rot_amount = Vector3(-event.relative.y, -event.relative.x, 0) * SENSITIVITY
			translate(separation*(Vector3(tan(rot_amount.y), -tan(rot_amount.x), 0)))
			position = orbit_point + (position - orbit_point).normalized()*separation
			
			look_at(orbit_point)


func _physics_process(delta):
	orbit_point_visual.global_position = orbit_point
	if update_orbit:
		ray_query.from = global_position
		ray_query.to = ray_query.from + project_ray_normal(get_viewport().get_mouse_position())*100
		var result = space_state.intersect_ray(ray_query)
		if result:
			orbit_point = result.position
		else:
			orbit_point = ray_query.to
		
		var diff = orbit_point - position
		translate(Vector3(basis.x.dot(diff), basis.y.dot(diff), 0))
		position = orbit_point + (position - orbit_point).normalized()*separation
		orbit_point_visual.global_position = orbit_point
		orbit_point_visual.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		update_orbit = false
