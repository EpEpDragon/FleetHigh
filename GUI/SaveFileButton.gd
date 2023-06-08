extends Button
class_name SaveFileButton

func _on_pressed():
	owner.load_ship(text + ".tres")
