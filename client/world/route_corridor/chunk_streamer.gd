extends Node3D
## W01: distance-based chunk load/unload + simple mesh LOD for prop clusters.

signal chunk_loaded(chunk_id: String)
signal chunk_unloaded(chunk_id: String)

@export var load_radius := 220.0
@export var unload_radius := 280.0
@export var lod_near := 40.0
@export var lod_far := 120.0

var _chunks: Dictionary = {} # id -> {origin: Vector3, node: Node3D, loaded: bool, factory: Callable}
var _focus := Vector3.ZERO

func register_chunk(chunk_id: String, origin: Vector3, factory: Callable) -> void:
	_chunks[chunk_id] = {
		"origin": origin,
		"node": null,
		"loaded": false,
		"factory": factory,
	}

func set_focus(pos: Vector3) -> void:
	_focus = pos
	_update()

func loaded_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for id in _chunks.keys():
		if bool(_chunks[id]["loaded"]):
			out.append(String(id))
	return out

func loaded_count() -> int:
	return loaded_ids().size()

func _update() -> void:
	for id in _chunks.keys():
		var meta: Dictionary = _chunks[id]
		var dist: float = _focus.distance_to(meta["origin"])
		if not bool(meta["loaded"]) and dist <= load_radius:
			_load_chunk(String(id), meta)
		elif bool(meta["loaded"]) and dist >= unload_radius:
			_unload_chunk(String(id), meta)
		elif bool(meta["loaded"]) and meta["node"] != null:
			_apply_lod(meta["node"] as Node3D, dist)

func _load_chunk(chunk_id: String, meta: Dictionary) -> void:
	var factory: Callable = meta["factory"]
	var node: Node3D = factory.call()
	if node == null:
		return
	node.name = "Chunk_%s" % chunk_id
	node.position = meta["origin"]
	add_child(node)
	meta["node"] = node
	meta["loaded"] = true
	_chunks[chunk_id] = meta
	chunk_loaded.emit(chunk_id)

func _unload_chunk(chunk_id: String, meta: Dictionary) -> void:
	var node: Node = meta["node"]
	if node != null and is_instance_valid(node):
		node.queue_free()
	meta["node"] = null
	meta["loaded"] = false
	_chunks[chunk_id] = meta
	chunk_unloaded.emit(chunk_id)

func _apply_lod(chunk: Node3D, dist: float) -> void:
	var detail := chunk.get_node_or_null("Detail") as Node3D
	var far := chunk.get_node_or_null("FarProxy") as Node3D
	if detail == null and far == null:
		return
	if dist <= lod_near:
		if detail:
			detail.visible = true
		if far:
			far.visible = false
	elif dist >= lod_far:
		if detail:
			detail.visible = false
		if far:
			far.visible = true
	else:
		if detail:
			detail.visible = true
		if far:
			far.visible = true
