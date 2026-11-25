extends SceneTree
## WORLD-DESIGN-002: smoke capture of playable Eternity Capital (4-class HUD).
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
	var play: Node3D = load(SCENE).instantiate()
	root.add_child(play)
	# Wait for capital load + hero spawn + class 0
	for i in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(OUT)
	print("PLAY_SMOKE ", err, " ", OUT)
	quit(0 if err == 0 else 1)
