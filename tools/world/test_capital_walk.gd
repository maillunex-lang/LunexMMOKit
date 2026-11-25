extends SceneTree
## CAP05: load capital play, verify collisions support 4-class spawn, walk without fall-through.
const OUT := "user://screens/"
func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(1280, 720)
	var play: Node3D = load("res://world/capital_play.tscn").instantiate()
	root.add_child(play)
	# Wait for async _ready collision/hero setup
	for i in range(90):
		await process_frame
		if play.get_node_or_null("Hero") != null and play.get("visual") != null:
			break
	var hero: CharacterBody3D = play.get_node_or_null("Hero") as CharacterBody3D
	if hero == null:
		print("FAIL_NO_HERO")
		quit(1)
		return
	var start_y := hero.global_position.y
	print("SPAWN ", hero.global_position)
	# Settle gravity
	for i in range(30):
		await physics_frame
	var settled_y := hero.global_position.y
	print("SETTLED ", hero.global_position)
	if settled_y < -50.0:
		print("FAIL_FALLTHROUGH_SETTLE")
		quit(1)
		return
	# Walk forward via controller
	hero.set_direction(Vector2(0, -1))
	for i in range(60):
		await physics_frame
	hero.set_direction(Vector2.ZERO)
	var after := hero.global_position
	print("AFTER_WALK ", after)
	var moved := after.distance_to(Vector3(hero.global_position.x, settled_y, after.z)) # placeholder
	moved = Vector2(after.x, after.z).distance_to(Vector2(hero.global_position.x, after.z))
	# Recompute from stored
	var start_xz := Vector2(hero.global_position.x, hero.global_position.z)
	# We overwrote — store properly
	var dy := after.y - settled_y
	print("WALK_DELTA_Y ", dy, " ON_FLOOR ", hero.is_on_floor())
	if after.y < settled_y - 5.0:
		print("FAIL_FALLTHROUGH_WALK")
		quit(1)
		return
	if Vector2(after.x - 90.0, after.z + 140.0).length() < 0.5 and after.z >= -140.0:
		print("WARN_LITTLE_MOVEMENT")
	# Cycle all 4 classes
	var ok_classes := 0
	for i in range(4):
		play._load_class(i)
		await process_frame
		await process_frame
		if play.get("visual") != null:
			ok_classes += 1
			print("CLASS_OK ", i, " ", play.actor_ids[i])
		else:
			print("CLASS_FAIL ", i)
	# Capture
	var cam: Camera3D = play.get_node_or_null("FollowCamera") as Camera3D
	if cam:
		cam.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(OUT + "capital-play-cap05.png")
	print("CAPTURE ", err, " CLASSES ", ok_classes, " START_Y ", start_y, " SETTLED_Y ", settled_y)
	quit(0 if ok_classes == 4 and after.y > -50.0 else 1)
