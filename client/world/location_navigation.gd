extends NavigationRegion3D
## FIX-001: bake NavigationMesh from static colliders (buildings/walls as obstacles).
## Water: geometry with meta navigation_water=true or name containing Water is excluded
## unless meta navigation_allow_water=true. Bridges/stairs: include StaticBody walk colliders.
## Mesh saved to .tres when bake_path set. Runtime + editor share this bake path.
## Server will own authoritative positions later; client nav is presentation pathfinding.

@export var bake_path: String = "" ## e.g. res://world/locations/eternity_capital/eternity_nav.tres
@export var agent_radius := 0.4
@export var agent_height := 1.6
@export var cell_size := 0.25
@export var cell_height := 0.25
@export var agent_max_climb := 0.75
@export var agent_max_slope := 45.0
## Fallback flat plane if bake yields empty (dev only).
@export var fallback_center := Vector3.ZERO
@export var fallback_half_extent := 90.0
@export var fallback_y := 0.05

signal location_bake_finished(ok: bool, polygon_count: int)

func rebuild(from_root: Node = null) -> void:
	var root: Node = from_root if from_root else _find_location_root()
	if root == null:
		root = get_parent()
	_exclude_water(root)
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.agent_radius = agent_radius
	mesh.agent_height = agent_height
	mesh.cell_size = cell_size
	mesh.cell_height = cell_height
	mesh.agent_max_climb = agent_max_climb
	mesh.agent_max_slope = agent_max_slope
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, src, root)
	NavigationServer3D.bake_from_source_geometry_data(mesh, src)
	var polys := mesh.get_polygon_count()
	if polys == 0:
		push_warning("LocationNavigation: bake empty — using fallback plane (FIX-001 incomplete geometry)")
		mesh = _fallback_plane()
		polys = mesh.get_polygon_count()
	navigation_mesh = mesh
	if bake_path != "" and bake_path.begins_with("res://"):
		# Editor/tools may save; runtime skips write if not in editor.
		if Engine.is_editor_hint():
			var err := ResourceSaver.save(mesh, bake_path)
			if err != OK:
				push_warning("LocationNavigation: failed save %s (%s)" % [bake_path, err])
	if is_inside_tree():
		await get_tree().physics_frame
		var map := get_world_3d().navigation_map
		NavigationServer3D.map_force_update(map)
	location_bake_finished.emit(polys > 0, polys)

func load_or_rebuild(from_root: Node = null) -> void:
	if bake_path != "" and ResourceLoader.exists(bake_path):
		var res = load(bake_path)
		if res is NavigationMesh and (res as NavigationMesh).get_polygon_count() > 0:
			navigation_mesh = res
			location_bake_finished.emit(true, navigation_mesh.get_polygon_count())
			return
	await rebuild(from_root)

func snapshot_mesh() -> NavigationMesh:
	if navigation_mesh == null:
		return null
	return navigation_mesh.duplicate(true) as NavigationMesh

func apply_mesh(mesh: NavigationMesh, revision: int = -1) -> void:
	navigation_mesh = mesh
	if revision >= 0 and get_parent() and get_parent().has_meta("location_revision"):
		get_parent().set_meta("location_revision", revision)

func _fallback_plane() -> NavigationMesh:
	var nav := NavigationMesh.new()
	nav.agent_radius = agent_radius
	nav.agent_height = agent_height
	var h := fallback_half_extent
	var c := fallback_center
	var y := fallback_y
	nav.vertices = PackedVector3Array([
		Vector3(c.x - h, y, c.z - h),
		Vector3(c.x + h, y, c.z - h),
		Vector3(c.x + h, y, c.z + h),
		Vector3(c.x - h, y, c.z + h),
	])
	nav.add_polygon(PackedInt32Array([0, 1, 2]))
	nav.add_polygon(PackedInt32Array([0, 2, 3]))
	return nav

func _exclude_water(root: Node) -> void:
	for n in root.find_children("*", "Node", true, false):
		var nm := String(n.name).to_lower()
		var is_water := nm.contains("water") or (n.has_meta("navigation_water") and bool(n.get_meta("navigation_water")))
		var allow := n.has_meta("navigation_allow_water") and bool(n.get_meta("navigation_allow_water"))
		if is_water and not allow:
			# Remove from nav parse by disabling collision layers temporarily via meta flag consumers,
			# and by setting collision_layer=0 on StaticBody water.
			if n is CollisionObject3D:
				n.set_meta("_nav_prev_layer", n.collision_layer)
				n.collision_layer = 0

func restore_water_layers(root: Node) -> void:
	for n in root.find_children("*", "CollisionObject3D", true, false):
		if n.has_meta("_nav_prev_layer"):
			n.collision_layer = int(n.get_meta("_nav_prev_layer"))
			n.remove_meta("_nav_prev_layer")

func _find_location_root() -> Node:
	var p := get_parent()
	while p:
		if p.has_meta("location_id") or String(p.name).begins_with("Eternity") or String(p.name).contains("Capital"):
			return p
		p = p.get_parent()
	return get_parent()
