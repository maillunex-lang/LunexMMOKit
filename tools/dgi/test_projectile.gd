extends SceneTree
const Projectile = preload("res://preview_projectile.gd")
func _initialize():
	call_deferred("run")
func run():
	var failures := 0
	for distance in [1.2,3.0]:
		var target := Node3D.new()
		root.add_child(target)
		target.position = Vector3(distance,0,0)
		target.set_meta("hp",100)
		var p := Projectile.new()
		root.add_child(p)
		p.target = target
		var result := []
		p.arrived.connect(func():
			target.set_meta("hp",90)
			result.append("hit"))
		p.expired.connect(func(): result.append("expired"))
		await create_timer(1.3).timeout
		var ok: bool = result == (["hit"] if distance<2.4 else ["expired"]) and target.get_meta("hp") == (90 if distance<2.4 else 100)
		if not ok: failures+=1
		print("distance=",distance," result=",result," hp=",target.get_meta("hp")," ok=",ok)
		target.free()
	print("FAILURES=",failures)
	quit(failures)
