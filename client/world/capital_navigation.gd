extends NavigationRegion3D
## Simple editable nav mesh for CAP05: flat walkable plane near spawn (refine later from walksurface).
@export var center := Vector3(90, 50, -140)
@export var half_extent := 80.0

func rebuild() -> void:
	var nav := NavigationMesh.new()
	var y := center.y
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
