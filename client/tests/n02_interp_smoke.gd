extends SceneTree
## N02: entity interpolator lerps between snapshots (client presentation).

const Interp = preload("res://network/entity_interpolator.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var i := Interp.new()
	i.set_render_delay(0.0)
	i.push_snapshot([{"id": 1, "pos": {"x": 0, "y": 1, "z": 0}}], 0.0)
	i.push_snapshot([{"id": 1, "pos": {"x": 10, "y": 1, "z": 0}}], 1.0)
	var mid: Vector3 = i.sample(1, 0.5)
	print("OK mid=", mid)
	if absf(mid.x - 5.0) > 0.05:
		fails.append("lerp mid got=%s" % mid)
	var end: Vector3 = i.sample(1, 1.0)
	if absf(end.x - 10.0) > 0.05:
		fails.append("lerp end")
	# Delayed render samples earlier pose
	i.set_render_delay(0.5)
	var delayed: Vector3 = i.sample(1, 1.0)
	print("OK delayed=", delayed)
	if absf(delayed.x - 5.0) > 0.1:
		fails.append("delay sample")
	if i.known_ids().is_empty():
		fails.append("ids")
	# World client module loads
	var wc = load("res://network/world_client.gd").new()
	if wc == null or wc.interp == null:
		fails.append("world_client")
	else:
		print("OK world_client")
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("N02_INTERP_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("N02_INTERP_SMOKE_FAIL")
	quit(1)
