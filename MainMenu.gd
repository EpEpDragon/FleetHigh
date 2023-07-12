extends Control

func _ready():
	var a := Vector2(10,5)
	var b := Vector2(-5.2,6.3)
	var lmax = max(a.length(), b.length())
	a /= lmax
	b /= lmax
	print(a.dot(b))

func _on_button_pressed():
	get_tree().change_scene_to_file("res://ship_builder.tscn")


func _on_start_pressed():
	pass # Replace with function body.
