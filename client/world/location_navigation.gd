extends NavigationRegion3D
## Runtime flat NavigationMesh for hand-authored locations (WE03 / GAME-SLICE).
## Auto-path uses this mesh — not hardcoded waypoint lists.

@export var center := Vector3.ZERO
@export var half_extent := 90.0
@export var y := 0.05

func rebuild() -> void:
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.4
	nav.agent_height = 1.6
	var h := half_extent
	nav.vertices = PackedVector3Array([
		Vector3(center.x - h, y, center.z - h),
		Vector3(center.x + h, y, center.z - h),
		Vector3(center.x + h, y, center.z + h),
		Vector3(center.x - h, y, center.z + h),
	])
	nav.add_polygon(PackedInt32Array([0, 1, 2]))
	nav.add_polygon(PackedInt32Array([0, 2, 3]))
	navigation_mesh = nav
	# Ensure region is on the default map after mesh assign.
	await get_tree().physics_frame
	NavigationServer3D.map_force_update(get_world_3d().navigation_map)
