extends Control

var Ship := preload("res://ship_components/Ship.tscn")
var SaveButton := preload("res://GUI/SaveFileButton.tscn")

# TODO Make a seperate file for these paths
var save_file_path := "user://save/"
var current_save_name : String
var selected_save_name : String

@onready var builder = get_parent()
@onready var save_list : VBoxContainer = $MarginContainer/VBoxContainer2/PanelContainer/SaveListScroll/SaveList
@onready var ship_name : LineEdit = $MarginContainer/VBoxContainer2/HBoxContainer/NameEdit


func _ready():
	populate_save_list()


func populate_save_list():
	var saves := DirAccess.get_files_at(save_file_path)
	# TODO Minor, maybe make this not delete everything
	for c in save_list.get_children():
		c.queue_free()
	for s in saves:
		var save_button : SaveFileButton = SaveButton.instantiate()
		save_button.text = s.trim_suffix(".tres")
		save_list.add_child(save_button)
		save_button.owner = self


func save_ship():
	ResourceSaver.save(builder.ship.ship_data, save_file_path + current_save_name)
	print("Saved: " + current_save_name)
	populate_save_list()


func load_ship(name):
	DirAccess.make_dir_absolute(save_file_path)
	if FileAccess.file_exists(save_file_path + name):
		builder.ship.next_key = 0
		for c in builder.ship.components:
			builder.ship.components[c].queue_free()
		for e in builder.ship.engines:
			e.queue_free()
		
		# Wait for queue free
		while !builder.ship.components.is_empty() || !builder.ship.engines.is_empty():
			await get_tree().process_frame
		
		builder.ship.ship_data = ResourceLoader.load(save_file_path + name).duplicate(true)
		# TODO Make this ship_instance referencing better
		builder.ship.ship_data.init_ship(builder.ship)
		ship_name.text = name.trim_suffix(".tres")
		current_save_name = name
		print("Loaded: "  + name)
	else:
		push_error("No save exists")


func new_ship():
	# TODO Figure out how to make ship ref not null when called on_ready
	if builder.ship:
		for c in builder.ship.components:
			builder.ship.components[c].queue_free()
		
		# Wait for queue free
		while !builder.ship.components.is_empty():
			await get_tree().process_frame
		
		var root_block = ComponentDefs.Hull.instantiate()
		builder.ship.add_child(root_block)
		root_block.preview = false
	ship_name.text = ""
	current_save_name = "New Ship.tres"
	print("New Ship")


func delete_ship():
	DirAccess.remove_absolute(save_file_path + current_save_name)
	populate_save_list()
	print("Deleted: " + current_save_name)
	new_ship()

func _on_name_edit_text_changed(new_text):
	current_save_name = new_text + ".tres"
	print("Current: " + current_save_name)

func _on_save_pressed():
	save_ship()

func _on_delete_pressed():
	delete_ship()

func _on_new_pressed():
	new_ship()
