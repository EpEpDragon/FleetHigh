extends Control

var map_position := Vector2.ZERO
var map_direction := Vector2.ZERO
var map_speed := 0.35
var zoom := 1.0

@onready var texture_rect : TextureRect = $TextureRect
#@onready var height_texture := texture_rect.texture

func _ready():
	texture_rect.texture.width = 1280 * 2
	texture_rect.texture.height = 1280 * 2

func _process(delta):
	map_position += map_direction * map_speed * delta
	texture_rect.material.set_shader_parameter("map_position", map_position)
	texture_rect.material.set_shader_parameter("zoom", zoom)
#	print("position: " + str(map_position) + " zoom: " + str(zoom))
	


func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		zoom += 0.1
		zoom = clamp(zoom,0, 1)
	if event.is_action_pressed("zoom_out"):
		zoom -= 0.1
		zoom = clamp(zoom,0, 1)
	
	if event.is_action_pressed("fly_forward"):
		map_direction -= Vector2(0,1)
	if event.is_action_released("fly_forward"):
		map_direction += Vector2(0,1)
	
	if event.is_action_pressed("fly_back"):
		map_direction += Vector2(0,1)
	if event.is_action_released("fly_back"):
		map_direction -= Vector2(0,1)
	
	if event.is_action_pressed("fly_left"):
		map_direction -= Vector2(1,0)
	if event.is_action_released("fly_left"):
		map_direction += Vector2(1,0)
	
	if event.is_action_pressed("fly_right"):
		map_direction += Vector2(1,0)
	if event.is_action_released("fly_right"):
		map_direction -= Vector2(1,0)
