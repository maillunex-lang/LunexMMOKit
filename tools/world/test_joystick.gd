extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var j = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	root.add_child(j)
	j.update_direction(j.size*0.5+Vector2(128,0))
	var ok: bool = j.direction.is_equal_approx(Vector2.RIGHT)
	j.update_direction(j.size*0.5+Vector2(1,0))
	ok = ok and j.direction == Vector2.ZERO
	j.reset()
	ok = ok and j.direction == Vector2.ZERO
	print("JOYSTICK_TEST ",ok)
	quit(0 if ok else 1)
