extends SceneTree
const Materials = preload("res://darklord_material.gd")
const Equipment = preload("res://equipment.gd")
func _initialize():
	call_deferred("run")
func load_model(path: String) -> Node3D:
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path,s)!=OK: return null
	return d.generate_scene(s)
func run():
	var base := "/home/gamedev/darklord-dgi/"
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(2.0,1.5,3.2)
	cam.look_at(Vector3(0,1.0,0))
	cam.current = true
	cam.fov = 38
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-35,-30,0)
	light.light_energy = 1.5
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#303746")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	root.add_child(env)
	for id in ["10001","20001","30001","40001"]:
		var a := load_model(base+"exports/"+id+".glb")
		var w := load_model(base+"exports/weapon-"+id.substr(0,1)+"00011000.glb")
		if a==null or w==null: quit(1); return
		var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+"material-params.json"))
		var count := Materials.apply(w, records[id.substr(0,1)+"00011000"][0], "/home/gamedev/Darklord")
		print("MATERIAL ",id," meshes=",count)
		if count==0: quit(4); return
		root.add_child(a)
		var marker := Equipment.attach_marker(a,"DM_R_Hand2",w)
		if marker==null: quit(2); return
		if id=="40001":
			if Equipment.attach_dual(a,w).size()!=2: quit(3); return
			w.free()
		var player := a.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
		for clip in ["stand","attack001"]:
			if not player.has_animation(clip): print("missing ",id,clip); continue
			player.play(clip)
			player.seek(player.get_animation(clip).length*0.45,true)
			player.pause()
			await process_frame
			await RenderingServer.frame_post_draw
			var result := root.get_texture().get_image().save_png(base+"screens/"+id+"-"+clip+".png")
			cam.position = Vector3(-2.0,1.5,3.2)
			cam.look_at(Vector3(0,1,0))
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(base+"screens/"+id+"-"+clip+"-alt.png")
			cam.position = Vector3(2.0,1.5,3.2)
			cam.look_at(Vector3(0,1,0))
			print(id," ",clip," save=",result)
		a.free()
	quit()
