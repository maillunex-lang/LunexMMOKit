extends SceneTree
## Smoke capture of playable Eternity Capital (must wait for capital + camera).
const SCENE := "res://world/locations/eternity_capital/eternity_play.tscn"
const OUT := "/home/gamedev/darklord-dgi/screens/eternity-play-smoke.png"

func _initialize():
	call_deferred("run")

func run():
	root.size = Vector2i(1280, 720)
	if not ResourceLoader.exists(SCENE):
		print("NO_SCENE")
		quit(1)
		return
	var play = load(SCENE).instantiate()
	if play == null:
		print("INSTANTIATE_FAIL")
		quit(1)
		return
	root.add_child(play)
	# Capital scene is heavy; wait until FollowCamera exists and is current.
	var cam: Camera3D = null
	for i in range(300):
		await process_frame
		cam = play.get_node_or_null("FollowCamera") as Camera3D
		if cam:
			cam.make_current()
			break
	for i in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var err := img.save_png(OUT)
	var mean := 0.0
	if img:
		# quick brightness sample to detect blank gray
		for y in range(0, img.get_height(), 64):
			for x in range(0, img.get_width(), 64):
				mean += img.get_pixel(x, y).v
		mean /= maxf(1.0, float((img.get_width()/64)*(img.get_height()/64)))
	print("PLAY_SMOKE ", err, " mean=", snapped(mean, 0.001), " cam=", cam != null, " ", OUT)
	quit(0 if err == 0 and cam != null else 1)
