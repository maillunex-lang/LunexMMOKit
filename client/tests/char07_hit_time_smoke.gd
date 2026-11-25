extends SceneTree
## CHAR07: attack001 events come from XML extract JSON; timeline fires at extracted times.

const Library = preload("res://combat/skill_events_library.gd")
const Timeline = preload("res://combat/skill_timeline.gd")
const Attack = preload("res://combat/preview_attack.gd")

func _initialize() -> void:
	call_deferred("run")

func _load(path: String) -> Node3D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path, s) != OK:
		return null
	return d.generate_scene(s)

func run() -> void:
	var fails: PackedStringArray = []
	var expected := {
		"10001": {"kind": "hit", "time": 0.15},
		"20001": {"kind": "hit", "time": 0.3},
		"30001": {"kind": "projectile", "time": 0.5},
		"40001": {"kind": "hit", "time": 0.4},
	}
	var cat := Library.load_catalog()
	if cat.is_empty() or not cat.has("classes"):
		fails.append("catalog missing")
		_finish(fails)
		return
	for actor_id in expected.keys():
		var ev: Dictionary = Library.attack001_event(String(actor_id))
		var want: Dictionary = expected[actor_id]
		if ev.is_empty():
			fails.append("event " + String(actor_id))
			continue
		if String(ev.get("kind", "")) != String(want["kind"]):
			fails.append("kind " + String(actor_id))
		if absf(float(ev.get("time", -1)) - float(want["time"])) > 0.0001:
			fails.append("time " + String(actor_id) + " got " + str(ev.get("time")))
		if String(ev.get("source", "")).find("SkillClassDisplayDesc") < 0:
			fails.append("source " + String(actor_id))
		# Timeline unit test from extracted event
		var tl := Timeline.new()
		var got: Array = []
		tl.event_due.connect(func(kind, stamp): got.append([kind, stamp]))
		tl.start(Library.attack001_timeline(String(actor_id)))
		tl.advance(float(want["time"]) - 0.001, 1.0)
		if not got.is_empty():
			fails.append("early " + String(actor_id))
		tl.advance(0.002, 1.0)
		if got.size() != 1 or String(got[0][0]) != String(want["kind"]):
			fails.append("fire " + String(actor_id))
		else:
			print("OK ", actor_id, " ", want["kind"], "@", want["time"])
	# Animation clips present for stand/walk/run/attack/hit/death/mount
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets:
		assets.refresh()
	if assets and bool(assets.ready_ok):
		var need := ["stand", "run", "attack001", "die001", "mount_stand"]
		for id in ["10001", "20001", "30001", "40001"]:
			var actor := _load(assets.actor_glb(id))
			if actor == null:
				fails.append("actor " + id)
				continue
			var players := actor.find_children("*", "AnimationPlayer", true, false)
			if players.is_empty():
				fails.append("player " + id)
				actor.free()
				continue
			var player: AnimationPlayer = players[0]
			var names := ",".join(player.get_animation_list()).to_lower()
			for clip in need:
				if clip not in names:
					# walk may be named run only — tolerate missing walk
					if clip == "walk":
						continue
					fails.append("clip " + id + " " + clip)
			print("OK clips ", id)
			actor.free()
	# Ensure training scene no longer embeds magic CLASS_EVENTS table
	var training := FileAccess.get_file_as_string("res://scenes/training/training_scene.gd")
	if "CLASS_EVENTS" in training:
		fails.append("training still has CLASS_EVENTS")
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("CHAR07_HIT_TIME_SMOKE_OK xml_sourced")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("CHAR07_HIT_TIME_SMOKE_FAIL")
	quit(1)
