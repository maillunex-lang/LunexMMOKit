extends RefCounted
## N02: interpolate remote entity positions between authoritative snapshots.

var _prev: Dictionary = {} # id -> {pos: Vector3, t: float}
var _next: Dictionary = {}
var _render_delay := 0.1
var _server_time := 0.0

func set_render_delay(sec: float) -> void:
	_render_delay = maxf(0.0, sec)

func push_snapshot(entities: Array, server_time: float = -1.0) -> void:
	if server_time < 0.0:
		_server_time += 0.05
	else:
		_server_time = server_time
	_prev = _next.duplicate(true)
	_next.clear()
	for e in entities:
		if not e is Dictionary:
			continue
		var id := int(e.get("id", 0))
		if id <= 0:
			continue
		var p: Variant = e.get("pos", {})
		var pos := Vector3.ZERO
		if p is Dictionary:
			pos = Vector3(float(p.get("x", 0)), float(p.get("y", 0)), float(p.get("z", 0)))
		elif p is Vector3:
			pos = p
		_next[id] = {"pos": pos, "t": _server_time, "raw": e}

func sample(entity_id: int, now: float = -1.0) -> Vector3:
	var t := now if now >= 0.0 else _server_time
	var render_t := t - _render_delay
	if not _next.has(entity_id):
		if _prev.has(entity_id):
			return _prev[entity_id]["pos"]
		return Vector3.ZERO
	var n: Dictionary = _next[entity_id]
	if not _prev.has(entity_id):
		return n["pos"]
	var p: Dictionary = _prev[entity_id]
	var t0: float = float(p["t"])
	var t1: float = float(n["t"])
	if t1 <= t0:
		return n["pos"]
	var alpha := clampf((render_t - t0) / (t1 - t0), 0.0, 1.0)
	var a: Vector3 = p["pos"]
	var b: Vector3 = n["pos"]
	return a.lerp(b, alpha)

func known_ids() -> PackedInt32Array:
	var out: PackedInt32Array = []
	for id in _next.keys():
		out.append(int(id))
	return out

func raw(entity_id: int) -> Dictionary:
	if _next.has(entity_id):
		return _next[entity_id].get("raw", {})
	return {}
