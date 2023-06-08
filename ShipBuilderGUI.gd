extends Control

var Ship := preload("res://ship_components/Ship.tscn")

var save_file_path = "user://save/"
var save_file_name = "ShipData.tres"
@onready var builder = get_parent()

func _on_save_pressed():
	ResourceSaver.save(builder.get_child(0).ship_data, save_file_path + save_file_name)


func _on_load_pressed():
	DirAccess.make_dir_absolute(save_file_path)
	for b in builder.ship.components:
		b.queue_free()
	if FileAccess.file_exists(save_file_path + save_file_name):
		builder.ship.ship_data = ResourceLoader.load(save_file_path + save_file_name).duplicate(true)
		# TODO Make this ship_instance referencing better
		builder.ship.ship_data.init_ship(builder.ship)
	else:
		builder.ship.ship_data = ShipData.new()
		var root_block = ComponentDefs.Hull.instantiate()
		builder.ship.add_child(root_block)
		root_block.preview = false
		print("No save exists")
