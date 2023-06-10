extends Label

func _process(delta):
	text = "FPS: " + str(Engine.get_frames_per_second()) + " PhxF: " + str(Engine.get_physics_frames())
