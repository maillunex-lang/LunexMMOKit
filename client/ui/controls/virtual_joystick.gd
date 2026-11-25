extends Control
class_name LunexJoystick
signal direction_changed(direction: Vector2)
@export_range(16.0,200.0) var radius := 64.0
@export_range(0.0,0.9) var deadzone := 0.15
var direction := Vector2.ZERO
var finger := -1
func _gui_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			update_direction(event.position)
			accept_event()
		elif not event.pressed and event.index == finger:
			reset()
			accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		update_direction(event.position)
		accept_event()
func update_direction(point: Vector2):
	var raw := ((point-size*0.5)/radius).limit_length()
	direction = Vector2.ZERO if raw.length()<deadzone else raw
	direction_changed.emit(direction)
	queue_redraw()
func reset():
	finger = -1
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()
func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()
func _draw():
	draw_circle(size*0.5,radius,Color(0.15,0.19,0.25,0.55))
	draw_arc(size*0.5,radius,0,TAU,64,Color(0.85,0.8,0.65,0.8),2)
	draw_circle(size*0.5+direction*radius,radius*0.36,Color(0.85,0.8,0.65,0.85))
