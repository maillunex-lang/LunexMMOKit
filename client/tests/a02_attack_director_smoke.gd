extends SceneTree
## A02: hit matches XML frame; cancel before hit emits nothing; no double event.

const Director = preload("res://combat/attack_director.gd")
const SkillEvents = preload("res://combat/skill_events_library.gd")

func _initialize() -> void:
	call_deferred("run")

func _load_actor(path: String) -> Node3D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path, s) != OK:
		return null
	return d.generate_scene(s)

func run() -> void:
	var fails: PackedStringArray = []
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets:
		assets.refresh()
	if assets == null or not bool(assets.ready_ok):
		fails.append("assets not ready")
		_finish(fails)
		return
	var source_root := String(assets.source_root)
	# Frame sync + single emission for warrior (hit @ 0.15)
	var actor: Node3D = _load_actor(assets.actor_glb("10001"))
	if actor == null:
		fails.append("load 10001")
		_finish(fails)
		return
	root.add_child(actor)
	var players := actor.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		fails.append("no AnimationPlayer")
		_finish(fails)
		return
	var ap: AnimationPlayer = players[0]
	if not ap.has_animation("attack001"):
		fails.append("no attack001")
		_finish(fails)
		return
	var dir: Node = Director.new()
	dir.name = "AttackDirector"
	root.add_child(dir)
	var hits: Array = []
	dir.impact.connect(func(): hits.append(ap.current_animation_position))
	if not dir.begin(ap, "10001", "attack001", 1.0, source_root):
		fails.append("begin failed")
		_finish(fails)
		return
	var want := float(SkillEvents.attack001_event("10001").get("time", 0.15))
	# Simulate frames until past hit
	var guard := 0
	while dir.active and guard < 600:
		guard += 1
		await process_frame
	if hits.is_empty():
		fails.append("no impact")
	elif hits.size() != 1:
		fails.append("double impact " + str(hits.size()))
	else:
		var frame_t: float = float(hits[0])
		if absf(frame_t - want) > 0.05:
			fails.append("frame mismatch got=%.3f want=%.3f" % [frame_t, want])
		else:
			print("OK frame sync hit@%.3f want=%.3f" % [frame_t, want])
	# Interrupt: cancel before hit → no emission
	hits.clear()
	if not dir.begin(ap, "10001", "attack001", 1.0, source_root):
		fails.append("begin2 failed")
	else:
		# Advance a few frames then cancel (still before 0.15 at 1x)
		for _i in 3:
			await process_frame
		dir.cancel()
		for _i in 10:
			await process_frame
		if dir.was_emitted() or not hits.is_empty():
			fails.append("cancel leaked event")
		else:
			print("OK cancel before hit")
	# Mage projectile single-shot
	hits.clear()
	var mage: Node3D = _load_actor(assets.actor_glb("30001"))
	if mage == null:
		fails.append("load 30001")
	else:
		root.add_child(mage)
		var mp: AnimationPlayer = mage.find_children("*", "AnimationPlayer", true, false)[0]
		var projs: Array = []
		dir.projectile.connect(func(): projs.append(1))
		if dir.begin(mp, "30001", "attack001", 1.0, source_root):
			guard = 0
			while dir.active and guard < 600:
				guard += 1
				await process_frame
			if projs.size() != 1:
				fails.append("mage projectile count=" + str(projs.size()))
			else:
				print("OK mage single projectile")
		else:
			fails.append("mage begin")
		mage.queue_free()
	actor.queue_free()
	dir.queue_free()
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("A02_ATTACK_DIRECTOR_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("A02_ATTACK_DIRECTOR_SMOKE_FAIL")
	quit(1)
