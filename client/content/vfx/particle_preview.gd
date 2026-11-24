extends RefCounted

static var MESH_CACHE := {}

static func _vec3(value: Variant, fallback := Vector3.ZERO) -> Vector3:
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback


static func _quat(value: Variant, fallback := Quaternion.IDENTITY) -> Quaternion:
	if value is Array and value.size() >= 4:
		return Quaternion(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback


static func _color(value: Variant, fallback := Color.WHITE) -> Color:
	if value is Array and value.size() >= 4:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback


static func _range(curve: Dictionary, fallback_min := 0.0, fallback_max := 0.0) -> Vector2:
	if curve.is_empty():
		return Vector2(fallback_min, fallback_max)
	var scalar := float(curve.get("scalar", fallback_max))
	var minimum := float(curve.get("minScalar", fallback_min))
	var result := Vector2(minimum, scalar)
	if result.x > result.y:
		result = Vector2(scalar, minimum)
	if is_equal_approx(result.x, result.y) and result.y == 0.0:
		result.y = scalar
	return result


static func _curve_value(curve: Dictionary, time: float) -> float:
	var keys: Array = curve.get("maxCurve", {}).get("keys", [])
	if keys.size() < 2:
		return float(curve.get("scalar", 1.0))
	time = clampf(time, float(keys[0].get("time", 0.0)), float(keys[keys.size() - 1].get("time", 1.0)))
	for index in range(keys.size() - 1):
		var a: Dictionary = keys[index]
		var b: Dictionary = keys[index + 1]
		var a_time := float(a.get("time", 0.0))
		var b_time := float(b.get("time", 1.0))
		if time >= a_time and time <= b_time:
			var span := maxf(0.000001, b_time - a_time)
			var t := inverse_lerp(a_time, b_time, time)
			var a_out := float(a.get("outSlope", 0.0))
			var b_in := float(b.get("inSlope", 0.0))
			var a_value := float(a.get("value", 0.0))
			var b_value := float(b.get("value", 1.0))
			if absf(a_out) < 100000.0 and absf(b_in) < 100000.0:
				var dt := span
				var m0 := a_out * dt
				var m1 := b_in * dt
				var t2 := t * t
				var t3 := t2 * t
				return (2.0 * t3 - 3.0 * t2 + 1.0) * a_value + (t3 - 2.0 * t2 + t) * m0 + (-2.0 * t3 + 3.0 * t2) * b_value + (t3 - t2) * m1
			return lerpf(a_value, b_value, t)
	return float(keys[keys.size() - 1].get("value", 1.0))


static func _lifetime(record: Dictionary) -> float:
	return maxf(0.05, _range(record.curves.get("startLifetime", {}), 1.0, 1.0).y)


static func _rate(record: Dictionary) -> float:
	return maxf(0.0, _range(record.curves.get("rateOverTime", {}), 0.0, 0.0).y)


static func _load_texture(material: Dictionary, source_root: String) -> Texture2D:
	var textures: Dictionary = material.get("textures", {})
	var candidates: Array = []
	for key in ["_MainTex", "_Texture", "_Textire", "_wenli", "_liuguang01"]:
		candidates.append_array(textures.get(key, []))
	for candidate in candidates:
		var path := source_root.path_join(str(candidate))
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null


static func _particle_material(record: Dictionary, source_root: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var color := Color.WHITE
	if record.materials.size() > 0:
		var source: Dictionary = record.materials[0]
		var texture := _load_texture(source, source_root)
		if texture != null:
			material.albedo_texture = texture
		if source.get("blend", "additive") == "alpha":
			material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		elif source.get("blend", "") == "multiply":
			material.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		var colors: Dictionary = source.get("colors", {})
		var tint: Variant = colors.get("_color", colors.get("_TintColor", colors.get("_Color", null)))
		if tint != null:
			color = _color(tint, Color.WHITE)
	material.albedo_color = color
	return material


static func _gradient_from_minmax(value: Dictionary) -> Gradient:
	var gradient := Gradient.new()
	var max_color := _color(value.get("maxColor", [1, 1, 1, 1]), Color.WHITE)
	var min_color := _color(value.get("minColor", [1, 1, 1, 1]), max_color)
	if min_color != max_color:
		gradient.colors = PackedColorArray([min_color, max_color])
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		return gradient
	var max_gradient: Dictionary = value.get("maxGradient", {})
	var color_keys: Array = max_gradient.get("colorKeys", [])
	var alpha_keys: Array = max_gradient.get("alphaKeys", [])
	var points := PackedColorArray()
	var offsets := PackedFloat32Array()
	for index in range(maxi(2, color_keys.size())):
		var item: Dictionary = color_keys[index] if index < color_keys.size() else (color_keys[color_keys.size() - 1] if color_keys.size() > 0 else {})
		var c := _color(item.get("color", [max_color.r, max_color.g, max_color.b, 1.0]), max_color)
		var alpha := max_color.a
		for alpha_item in alpha_keys:
			if absf(float(alpha_item.get("time", 0.0)) - float(item.get("time", 0.0))) < 0.02:
				alpha = float(alpha_item.get("alpha", alpha))
				break
		c.a = alpha
		points.append(c)
		offsets.append(clampf(float(item.get("time", 0.0)), 0.0, 1.0))
	if points.size() < 2:
		points = PackedColorArray([max_color, max_color])
		offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = points
	gradient.offsets = offsets
	return gradient


static func _load_mesh(path: String) -> Mesh:
	if path == "":
		return null
	if MESH_CACHE.has(path):
		return MESH_CACHE[path]
	var mesh: Mesh = null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) == OK:
		var scene := doc.generate_scene(state)
		if scene != null:
			var meshes := scene.find_children("*", "MeshInstance3D", true, false)
			if meshes.size() > 0:
				mesh = (meshes[0] as MeshInstance3D).mesh
	MESH_CACHE[path] = mesh
	return mesh


static func _configure_emission(particles: CPUParticles3D, record: Dictionary) -> void:
	var shape: Dictionary = record.get("shape", {})
	var shape_type := int(shape.get("type", 0))
	var radius := float(shape.get("radius", 0.0))
	var box := _vec3(shape.get("box", [1, 1, 1]), Vector3.ONE)
	match shape_type:
		5:
			particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			particles.emission_box_extents = Vector3(absf(box.x), absf(box.y), absf(box.z)) * 0.5
		0, 1, 2, 3, 8:
			particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			particles.emission_sphere_radius = maxf(0.001, radius)
		4, 10:
			particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
			particles.spread = clampf(float(shape.get("angle", 25.0)), 0.0, 180.0)
		_:
			particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			particles.emission_sphere_radius = maxf(0.001, radius)


static func _configure_particles(record: Dictionary, source_root: String) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = str(record.get("name", "emitter")).validate_node_name()
	var curves: Dictionary = record.get("curves", {})
	var lifetime := _lifetime(record)
	particles.lifetime = lifetime
	particles.preprocess = record.duration if bool(record.get("prewarm", false)) else 0.0
	particles.local_coords = bool(record.get("local_coords", true))
	var bursts: Array = record.get("emission", {}).get("bursts", [])
	var rate := _rate(record)
	var burst_count := 0
	for burst in bursts:
		burst_count = maxi(burst_count, int(burst.get("maxCount", burst.get("minCount", 0))))
	particles.amount = clampi(max(ceili(rate * lifetime), burst_count, 1), 1, clampi(int(record.get("maxNumParticles", 1000)), 1, 4096))
	particles.one_shot = bursts.size() > 0 or not bool(record.get("loop", true))
	particles.explosiveness = 1.0 if bursts.size() > 0 else 0.0
	particles.emitting = true
	var speed := _range(curves.get("startSpeed", {}), 0.0, 0.0)
	particles.initial_velocity_min = speed.x
	particles.initial_velocity_max = speed.y
	var rotation := _range(curves.get("startRotation", {}), 0.0, 0.0)
	particles.angular_velocity_min = rotation.x
	particles.angular_velocity_max = rotation.y
	var gravity := _range(curves.get("gravityModifier", {}), 0.0, 0.0)
	particles.gravity = Vector3.DOWN * 9.81 * gravity.y
	_configure_emission(particles, record)
	var color_curve: Dictionary = curves.get("startColor", {})
	particles.color_ramp = _gradient_from_minmax(color_curve)
	var velocity: Dictionary = record.get("overLifetime", {}).get("velocity", {})
	if bool(velocity.get("enabled", false)):
		var vx := _range(velocity.get("x", {}), 0.0, 0.0)
		var vy := _range(velocity.get("y", {}), 0.0, 0.0)
		var vz := _range(velocity.get("z", {}), 0.0, 0.0)
		particles.set_meta("velocity_over_lifetime", {"x": vx, "y": vy, "z": vz})
	var uv: Dictionary = record.get("uv", {})
	if bool(uv.get("enabled", false)):
		particles.set_meta("source_uv", uv)
	var start_size := _range(curves.get("startSize", {}), 1.0, 1.0)
	var over_size: Dictionary = record.get("overLifetime", {}).get("size", {})
	var mesh: Mesh = null
	if int(record.get("render_mode", 0)) == 4:
		mesh = _load_mesh(str(record.get("mesh_glb", "")))
	var material := _particle_material(record, source_root)
	if mesh == null:
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * maxf(0.01, start_size.y)
		quad.material = material
		mesh = quad
	particles.mesh = mesh
	particles.material_override = material
	particles.set_meta("source_duration", record.get("duration", lifetime))
	particles.set_meta("source_bursts", bursts)
	particles.set_meta("source_start_delay", curves.get("startDelay", {}))
	particles.set_meta("source_over_size", over_size)
	particles.set_meta("source_over_color", record.get("overLifetime", {}).get("color", {}))
	return particles


static func build(payload: Variant, source_root: String) -> Node3D:
	var effect := Node3D.new()
	var records: Array = []
	var hierarchy: Array = []
	if payload is Dictionary and payload.has("emitters"):
		records = payload.get("emitters", [])
		hierarchy = payload.get("hierarchy", [])
	elif payload is Array:
		records = payload
	var by_id: Dictionary = {}
	for item in hierarchy:
		if not item is Dictionary:
			continue
		var node := Node3D.new()
		node.name = str(item.get("name", "node")).validate_node_name()
		node.position = _vec3(item.get("position", [0, 0, 0]), Vector3.ZERO)
		node.quaternion = _quat(item.get("rotation", [0, 0, 0, 1]), Quaternion.IDENTITY)
		node.scale = _vec3(item.get("scale", [1, 1, 1]), Vector3.ONE)
		by_id[int(item.get("id", 0))] = node
	for item in hierarchy:
		if not item is Dictionary:
			continue
		var node: Node3D = by_id[int(item.get("id", 0))]
		var parent_id := int(item.get("parent", 0))
		var parent: Node = by_id.get(parent_id, effect)
		parent.add_child(node)
	for record in records:
		if not record is Dictionary:
			continue
		var particles := _configure_particles(record, source_root)
		var transform_id := int(record.get("transform_id", 0))
		var parent: Node = by_id.get(int(record.get("parent_transform_id", 0)), effect)
		if by_id.has(transform_id):
			parent = by_id[transform_id]
		parent.add_child(particles)
	if effect.get_child_count() == 0 and records.size() > 0:
		for record in records:
			if record is Dictionary:
				effect.add_child(_configure_particles(record, source_root))
	effect.set_meta("source_emitters", records.size())
	return effect


static func emitter_count(effect: Node) -> int:
	return effect.find_children("*", "CPUParticles3D", true, false).size()


static func dispose(effect: Node) -> void:
	if effect == null:
		return
	for particles in effect.find_children("*", "CPUParticles3D", true, false):
		if particles is CPUParticles3D:
			particles.emitting = false
			particles.mesh = null
			particles.material_override = null
	effect.free()
