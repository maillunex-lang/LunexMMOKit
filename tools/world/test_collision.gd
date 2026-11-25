extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var scene: Node3D = load("res://world/imported/mh_scene_07_corrected.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var nav: MeshInstance3D = scene.get_node("Object_477512445/Object_359807223/Object_1817125895/NavigationSource")
	var bounds: AABB = nav.global_transform * nav.get_aabb()
	var center := bounds.get_center()
	var hits := 0
	for x in range(-2,3):
		for z in range(-2,3):
			var p := center + Vector3(x*2,0,z*2)
			var q := PhysicsRayQueryParameters3D.create(p+Vector3.UP*100,p-Vector3.UP*100)
			var result := root.world_3d.direct_space_state.intersect_ray(q)
			if not result.is_empty():
				hits += 1
	print("COLLISION_RAYS ",hits,"/25")
	quit(0 if hits == 25 else 1)
