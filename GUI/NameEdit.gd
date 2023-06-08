extends LineEdit

# Remove focus if click outside
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0), size).has_point(evLocal.position):
			release_focus()
