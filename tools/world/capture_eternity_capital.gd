extends SceneTree
## WORLD-DESIGN-002 acceptance captures for Eternity Capital.
const SCENE := "res://world/locations/eternity_capital/eternity_capital.tscn"
const OUT := "/home/gamedev/darklord-dgi/screens/"

func _initialize():
	call_deferred("run")

func shot(city: Node3D, name: String, pos: Vector3, look: Vector3, fov := 55.0) -> int:
	var cam := city.get_node_or_null("CaptureCam") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "CaptureCam"
		city.add_child(cam)
	cam.fov = fov
	cam.far = 1200.0
	cam.position = pos
	cam.look_at(look)
	cam.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(OUT + name)
	print("SHOT ", name, " ", err)
	return err

func run():
	root.size = Vector2i(1280, 720)
	if not ResourceLoader.exists(SCENE):
		print("NO_SCENE")
		quit(1)
		return
	var city: Node3D = load(SCENE).instantiate()
	root.add_child(city)
	await process_frame
	await process_frame
	var errs := 0
	errs += await shot(city, "eternity-capital-birdseye.png", Vector3(0, 140, 40), Vector3(0, 0, 0), 50.0)
	errs += await shot(city, "eternity-capital-plaza.png", Vector3(18, 8, 28), Vector3(0, 3, 0), 55.0)
	errs += await shot(city, "eternity-capital-avenue.png", Vector3(0, 6, -50), Vector3(0, 4, 0), 60.0)
	errs += await shot(city, "eternity-capital-gate.png", Vector3(0, 10, -95), Vector3(0, 6, -78), 50.0)
	errs += await shot(city, "eternity-capital-water.png", Vector3(16, 6, -20), Vector3(0, 1, -30), 55.0)
	errs += await shot(city, "eternity-capital-playercam.png", Vector3(0, 5.5, -58), Vector3(0, 3, -40), 60.0)
	errs += await shot(city, "eternity-capital-market.png", Vector3(22, 7, 4), Vector3(34, 2, 0), 55.0)
	print("CAPTURE_DONE errs ", errs)
	quit(0 if errs == 0 else 1)
