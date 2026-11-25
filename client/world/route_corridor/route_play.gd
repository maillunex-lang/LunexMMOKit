extends Node3D
## W01 — extended test corridor: capital → mid hunt → shard ruins (~650 m / ~3.6 min @ 3 m/s).
## Chunks stream by distance; Detail/FarProxy LOD; full-length NavigationRegion3D.

const ChunkStreamer = preload("res://world/route_corridor/chunk_streamer.gd")

## Walk distance along +Z. 650 m / 3.0 m/s hero speed ≈ 217 s ≈ 3.6 min.
const ROUTE_LENGTH_M := 650.0
const CHUNK_SPACING := 216.0
const WALK_SPEED := 3.0

var streamer: Node3D
var nav: NavigationRegion3D
var hero_proxy: Node3D
var mem_baseline_kb := 0

func _ready() -> void:
	set_meta("location_id", "route_corridor")
	_build_ground()
	streamer = ChunkStreamer.new()
	streamer.name = "ChunkStreamer"
	add_child(streamer)
	_register_chunks()
	hero_proxy = Node3D.new()
	hero_proxy.name = "HeroProxy"
	add_child(hero_proxy)
	hero_proxy.position = Vector3(0, 0.1, 2.0)
	streamer.set_focus(hero_proxy.global_position)
	mem_baseline_kb = _mem_kb()
	await _build_nav()

func route_length_m() -> float:
	return ROUTE_LENGTH_M

func estimated_walk_seconds(speed: float = WALK_SPEED) -> float:
	return ROUTE_LENGTH_M / maxf(speed, 0.01)

func estimated_walk_minutes(speed: float = WALK_SPEED) -> float:
	return estimated_walk_seconds(speed) / 60.0

func advance_hero(z: float) -> void:
	hero_proxy.position = Vector3(0, 0.1, clampf(z, 0.0, ROUTE_LENGTH_M))
	streamer.set_focus(hero_proxy.global_position)

func loaded_chunk_count() -> int:
	return streamer.loaded_count()

func mem_delta_kb() -> int:
	return _mem_kb() - mem_baseline_kb

func query_path() -> PackedVector3Array:
	if nav == null or not is_inside_tree():
		return PackedVector3Array()
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_force_update(map)
	var from := Vector3(0, 0.2, 2.0)
	var to := Vector3(0, 0.2, ROUTE_LENGTH_M - 2.0)
	return NavigationServer3D.map_get_path(map, from, to, true)

func _mem_kb() -> int:
	return int(OS.get_static_memory_usage() / 1024)

func _build_ground() -> void:
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "RouteFloor"
	var box := BoxMesh.new()
	box.size = Vector3(24.0, 0.4, ROUTE_LENGTH_M + 20.0)
	floor_mi.mesh = box
	floor_mi.position = Vector3(0, -0.2, ROUTE_LENGTH_M * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.32, 0.26)
	floor_mi.set_surface_override_material(0, mat)
	add_child(floor_mi)
	var body := StaticBody3D.new()
	body.name = "RouteFloorBody"
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape.shape = box_shape
	body.add_child(shape)
	body.position = floor_mi.position
	add_child(body)
	# Side rails so path stays on corridor
	for side in [-1.0, 1.0]:
		var wall := StaticBody3D.new()
		wall.name = "Rail_%s" % ("L" if side < 0 else "R")
		var cs := CollisionShape3D.new()
		var ws := BoxShape3D.new()
		ws.size = Vector3(1.0, 3.0, ROUTE_LENGTH_M)
		cs.shape = ws
		wall.add_child(cs)
		wall.position = Vector3(side * 12.5, 1.5, ROUTE_LENGTH_M * 0.5)
		add_child(wall)

func _build_nav() -> void:
	nav = NavigationRegion3D.new()
	nav.name = "NavigationRegion3D"
	nav.set_script(load("res://world/location_navigation.gd"))
	add_child(nav)
	# Corridor is long on Z; fallback plane covers full route if collider bake is sparse.
	nav.set("fallback_center", Vector3(0, 0, ROUTE_LENGTH_M * 0.5))
	nav.set("fallback_half_extent", maxf(ROUTE_LENGTH_M * 0.55, 40.0))
	nav.set("fallback_y", 0.05)
	nav.set("cell_size", 0.5)
	nav.set("bake_path", "")
	await nav.rebuild(self)

func _register_chunks() -> void:
	var specs := [
		{"id": "capital_gate", "z": 0.0, "tint": Color(0.45, 0.55, 0.75)},
		{"id": "ashen_mid", "z": CHUNK_SPACING, "tint": Color(0.55, 0.4, 0.3)},
		{"id": "hunt_band", "z": CHUNK_SPACING * 2.0, "tint": Color(0.35, 0.5, 0.35)},
		{"id": "shard_approach", "z": CHUNK_SPACING * 3.0, "tint": Color(0.5, 0.35, 0.55)},
	]
	for spec in specs:
		var sid: String = String(spec["id"])
		var z: float = float(spec["z"])
		var tint: Color = spec["tint"]
		streamer.register_chunk(sid, Vector3(0, 0, z), func() -> Node3D: return _make_chunk(sid, tint))

func _make_chunk(chunk_id: String, tint: Color) -> Node3D:
	var root := Node3D.new()
	root.set_meta("chunk_id", chunk_id)
	var detail := Node3D.new()
	detail.name = "Detail"
	root.add_child(detail)
	# Landmark pillar + prop cluster (detail LOD)
	for i in 5:
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.4 + i * 0.05
		cyl.bottom_radius = 0.5 + i * 0.05
		cyl.height = 2.0 + i * 0.8
		mi.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint.lightened(0.05 * i)
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(-6.0 + i * 3.0, cyl.height * 0.5, 4.0)
		detail.add_child(mi)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = cyl.bottom_radius
		shape.height = cyl.height
		cs.shape = shape
		body.add_child(cs)
		body.position = mi.position
		detail.add_child(body)
	var far := MeshInstance3D.new()
	far.name = "FarProxy"
	var proxy := BoxMesh.new()
	proxy.size = Vector3(14.0, 4.0, 6.0)
	far.mesh = proxy
	var far_mat := StandardMaterial3D.new()
	far_mat.albedo_color = tint.darkened(0.25)
	far.set_surface_override_material(0, far_mat)
	far.position = Vector3(0, 2.0, 4.0)
	far.visible = false
	root.add_child(far)
	var label := Label3D.new()
	label.text = chunk_id
	label.position = Vector3(0, 6.0, 0)
	label.font_size = 48
	root.add_child(label)
	return root
