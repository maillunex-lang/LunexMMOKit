extends RefCounted
static func build(records: Array, source_root: String) -> Node3D:
	var effect := Node3D.new()
	for record in records:
		var textures: Dictionary = record.materials[0].textures if record.materials.size()==1 else {}
		var paths: Array = textures.get("_MainTex",textures.get("_Texture",[]))
		if paths.size()!=1: continue
		var img := Image.load_from_file(source_root.path_join(paths[0]))
		if img == null or img.is_empty(): continue
		var p := CPUParticles3D.new()
		p.name = record.name.validate_node_name()
		var c: Dictionary = record.curves
		p.lifetime = maxf(0.05,c.get("startLifetime",{}).get("scalar",1.0))
		p.amount = clampi(ceili(c.get("rateOverTime",{}).get("scalar",0.0)*p.lifetime),1,64)
		p.one_shot = not record.loop
		p.explosiveness = 1.0 if p.one_shot else 0.0
		p.gravity = Vector3.DOWN * 9.81 * c.get("gravityModifier",{}).get("scalar",0.0)
		p.initial_velocity_min = maxf(0.0,c.get("startSpeed",{}).get("scalar",0.0))
		p.initial_velocity_max = p.initial_velocity_min
		var q := QuadMesh.new()
		q.size = Vector2.ONE * maxf(0.01,c.get("startSize",{}).get("scalar",1.0))
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.albedo_texture = ImageTexture.create_from_image(img)
		q.material = m
		p.mesh = q
		effect.add_child(p)
	return effect
