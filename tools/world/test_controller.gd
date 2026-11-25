extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var scene: Node3D = load("res://world/imported/mh_scene_07_navigation.tscn").instantiate()
	root.add_child(scene)
	var body := CharacterBody3D.new()
	body.set_script(load("res://actors/hero_controller.gd"))
	scene.add_child(body)
	body.position=Vector3(129,53,-121)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.35
	capsule.height=1.8
	shape.shape=capsule
	shape.position.y=0.9
	body.add_child(shape)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var args := OS.get_cmdline_user_args()
	var id := args[0] if args.size()>0 else "10001"
	if doc.append_from_file(ProjectSettings.globalize_path("res://../assets/studio/exports/"+id+".glb"),state)!=OK:
		quit(1)
		return
	var hero := doc.generate_scene(state) as Node3D
	body.add_child(hero)
	body.visual=hero
	body.animator=hero.find_children("*","AnimationPlayer",true,false)[0]
	var cam := Camera3D.new()
	cam.set_script(load("res://world/follow_camera.gd"))
	scene.add_child(cam)
	cam.target=body
	cam.position=body.position+cam.follow_offset
	cam.look_at(body.position+Vector3.UP)
	body.camera=cam
	var joystick = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	root.add_child(joystick)
	joystick.direction_changed.connect(body.set_direction)
	for i in range(20): await physics_frame
	var start := body.position
	joystick.update_direction(joystick.size*0.5+Vector2(64,0))
	for i in range(60): await physics_frame
	var distance := body.position.distance_to(start)
	var running: bool = body.animator.current_animation=="run"
	joystick.reset()
	for i in range(10): await physics_frame
	var ok: bool = distance>2 and running and body.animator.current_animation=="stand" and absf(body.velocity.x)<0.01 and body.is_on_floor()
	print("CONTROLLER ",id," distance=",distance," run=",running," stop=",body.animator.current_animation," ok=",ok)
	quit(0 if ok else 1)
