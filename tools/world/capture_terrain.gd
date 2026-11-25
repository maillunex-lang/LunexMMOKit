extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var city:Node3D=load("res://world/imported/capital_geometry_v6.tscn").instantiate()
	root.add_child(city)
	root.size=Vector2i(1280,720)
	var target:MeshInstance3D=city.get_node("Prefab_114532972/Mesh_33145162989200000")
	for m in city.find_children("*","MeshInstance3D",true,false):
		m.visible=m==target
	var b:AABB=target.global_transform*target.get_aabb()
	print("TERRAIN ",b," SURFACES ",target.mesh.get_surface_count()," MATERIAL ",target.get_active_material(0))
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0.2,0.3,0.4)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=1.0
	city.add_child(env)
	var cam:=Camera3D.new()
	city.add_child(cam)
	cam.position=b.get_center()+Vector3(0,1,0.1).normalized()*b.size.length()
	cam.far=2000
	cam.look_at(b.get_center())
	cam.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var err:=root.get_texture().get_image().save_png("user://screens/capital-terrain-isolated.png")
	print("CAPTURE ",err)
	quit(err)
