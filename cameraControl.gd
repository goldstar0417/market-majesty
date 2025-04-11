extends Camera2D

var drag_start_position = Vector2.ZERO
var camera_start_position = Vector2.ZERO
var dragging = false

func _unhandled_input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			drag_start_position = event.position
			camera_start_position = position
			dragging = true
		else:
			dragging = false
			
	elif dragging and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		position = camera_start_position - (event.position - drag_start_position)
