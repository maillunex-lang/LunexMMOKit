extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var scene: Node3D = load("res://world/imported/mh_scene_07_navigation.tscn").instantiate()
	root.add_child(scene)
	var region: NavigationRegion3D = scene.get_node("WalkNavigation")
	for i in range(10): await physics_frame
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	var path := NavigationServer3D.map_get_path(map,Vector3(129,53,-121),Vector3(135,53,-121),true)
	if path.size()<2:
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var actor_id := args[0] if not args.is_empty() else "10001"
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path("res://../assets/studio/exports/"+actor_id+".glb"),state)!=OK:
		quit(1)
		return
	var hero := doc.generate_scene(state) as Node3D
	var body := CharacterBody3D.new()
	scene.add_child(body)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.35
	capsule.height=1.8
	shape.shape=capsule
	shape.position.y=0.9
	body.add_child(shape)
	body.add_child(hero)
	body.global_position=path[0]+Vector3.UP*0.1
	var player := hero.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	print("CLIPS ",player.get_animation_list())
	var clip := ""
	for name in player.get_animation_list():
		if name.to_lower()=="run":
			clip=name
	if clip.is_empty():
		quit(1)
		return
	player.play(clip)
	var index := 1
	for i in range(600):
		await physics_frame
		var delta := path[index]-body.global_position
		delta.y=0
		if delta.length()<0.15:
			index+=1
			if index>=path.size(): break
			continue
		var dir := delta.normalized()
		body.velocity=dir*3.0+Vector3.DOWN*2.0
		body.move_and_slide()
		hero.rotation.y=atan2(dir.x,dir.z)
	var error := Vector2(body.global_position.x-path[-1].x,body.global_position.z-path[-1].z).length()
	player.play("stand")
	print("HERO_WALK actor=",actor_id," clip=",clip," reached=",index>=path.size()," error=",error," floor=",body.is_on_floor()," pos=",body.global_position)
	quit(0 if error<0.2 and body.is_on_floor() else 1)
