extends SceneTree
## WORLD-DESIGN-002: build reusable editable PackedScene kits from library GLBs + textures.
const MESH_DIR := "res://world/library/meshes/"
const TEX_DIR := "res://world/library/textures/"
const KIT_DIR := "res://world/library/kits/"
const OUT_META := "/home/gamedev/darklord-dgi/environment-kits.json"

var KIT_DEFS := [
	{"id": "gate_main", "category": "gate", "mesh": "gate_main.glb", "tex": "build_jz03.png", "yaw": 0.0, "source": "cs_yw_xsc_chengmengqian02"},
	{"id": "palace_01", "category": "palace", "mesh": "palace_gonghui01.glb", "tex": "build_jz02.png", "yaw": 0.0, "source": "cs_zhucheng_gonghui01"},
	{"id": "palace_02", "category": "palace", "mesh": "palace_gonghui02.glb", "tex": "build_jz01.png", "yaw": 0.0, "source": "cs_zhucheng_gonghui02"},
	{"id": "arch_jz01", "category": "building", "mesh": "arch_jz01.glb", "tex": "build_jz01.png", "yaw": 0.0, "source": "cs_zhucheng_jz01"},
	{"id": "arch_jz02", "category": "building", "mesh": "arch_jz02.glb", "tex": "build_jz03.png", "yaw": 0.0, "source": "cs_zhucheng_jz02"},
	{"id": "arch_jz03", "category": "building", "mesh": "arch_jz03.glb", "tex": "build_jz04.png", "yaw": 0.0, "source": "cs_zhucheng_jz03"},
	{"id": "house_01", "category": "building", "mesh": "house_fangzi01.glb", "tex": "build_jz01.png", "yaw": 0.0, "source": "cs_zhucheng_fangzi01"},
	{"id": "house_02", "category": "building", "mesh": "house_fangzi02.glb", "tex": "build_jz02.png", "yaw": 0.0, "source": "cs_zhucheng_fangzi02"},
	{"id": "house_03", "category": "building", "mesh": "house_fangzi03.glb", "tex": "build_jz05.png", "yaw": 0.0, "source": "cs_zhucheng_fangzi03"},
	{"id": "shop_01", "category": "building", "mesh": "shop_zawu01.glb", "tex": "build_jz04.png", "yaw": 0.0, "source": "cs_zhucheng_zawu01"},
	{"id": "shop_04", "category": "building", "mesh": "shop_zawu04.glb", "tex": "build_jz05.png", "yaw": 0.0, "source": "cs_zhucheng_zawu04"},
	{"id": "shop_07", "category": "building", "mesh": "shop_zawu07.glb", "tex": "build_jz02.png", "yaw": 0.0, "source": "cs_zhucheng_zawu07"},
	{"id": "bridge_01", "category": "bridge", "mesh": "bridge_qiao.glb", "tex": "wall_qiang01.png", "yaw": 0.0, "source": "FB_14_qiao"},
	{"id": "fountain_01", "category": "fountain", "mesh": "fountain_penquan.glb", "tex": "build_jz03.png", "yaw": 0.0, "source": "cs_zhucheng_penquan"},
	{"id": "statue_01", "category": "statue", "mesh": "statue_01.glb", "tex": "build_jz01.png", "yaw": 0.0, "source": "cs_zhucheng_diaoxiang01"},
	{"id": "statue_base", "category": "statue", "mesh": "statue_base_01.glb", "tex": "wall_qiang01.png", "yaw": 0.0, "source": "cs_zhucheng_diaoxiangtai01"},
	{"id": "crystal_01", "category": "crystal", "mesh": "crystal_mesh.glb", "tex": "", "yaw": 0.0, "source": "cs_zhucheng_shuijing", "special": "crystal"},
	{"id": "water_01", "category": "water", "mesh": "water_plane.glb", "tex": "", "yaw": 0.0, "source": "cs_yw_zhucheng_water", "special": "water"},
	{"id": "tree_01", "category": "tree", "mesh": "tree_01.glb", "tex": "blossom.png", "yaw": 0.0, "source": "cs_zhucheng_shu01"},
	{"id": "tree_plant", "category": "tree", "mesh": "tree_plant.glb", "tex": "blossom.png", "yaw": 0.0, "source": "cs_zhucheng_zhiwu01"},
	{"id": "bush_01", "category": "bush", "mesh": "bush_01.glb", "tex": "splat_grass.png", "yaw": 0.0, "source": "cs_zhucheng_guanmu01"},
	{"id": "lamp_01", "category": "prop", "mesh": "lamp_01.glb", "tex": "build_jz04.png", "yaw": 0.0, "source": "cs_zhucheng_ludeng01"},
	{"id": "rock_01", "category": "rock", "mesh": "rock_01.glb", "tex": "splat_dirt.png", "yaw": 0.0, "source": "cs_haitan_shitou01"},
	{"id": "rock_02", "category": "rock", "mesh": "rock_02.glb", "tex": "splat_sand.png", "yaw": 0.0, "source": "cs_haitan_shitou02"},
]

func _initialize():
	call_deferred("run")

func mat_from_tex(path: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if path != "" and ResourceLoader.exists(TEX_DIR + path):
		m.albedo_texture = load(TEX_DIR + path)
	m.roughness = 0.85
	return m

func crystal_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.75, 1.0, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.2, 0.55, 1.0)
	m.emission_energy_multiplier = 1.8
	m.roughness = 0.2
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func water_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.18, 0.4, 0.55, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.12
	m.metallic = 0.05
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func load_glb_root(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D

func ground_kit() -> void:
	var root := Node3D.new()
	root.name = "Kit_ground_tile"
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	plane.subdivide_width = 4
	plane.subdivide_depth = 4
	mi.mesh = plane
	var m := mat_from_tex("splat_grass.png")
	m.uv1_scale = Vector3(8, 8, 8)
	mi.set_surface_override_material(0, m)
	root.add_child(mi)
	mi.owner = root
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	col.shape = box
	col.position.y = -0.1
	body.add_child(col)
	col.owner = root
	root.set_meta("kit_id", "ground_tile")
	root.set_meta("category", "terrain")
	_save_kit(root, "ground_tile")

func road_kit() -> void:
	var root := Node3D.new()
	root.name = "Kit_road_tile"
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 20)
	mi.mesh = plane
	var m := mat_from_tex("ground_dm02.png")
	m.uv1_scale = Vector3(4, 6, 1)
	mi.set_surface_override_material(0, m)
	root.add_child(mi)
	mi.owner = root
	var body := StaticBody3D.new()
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 0.2, 20)
	col.shape = box
	col.position.y = -0.1
	body.add_child(col)
	col.owner = root
	root.set_meta("kit_id", "road_tile")
	root.set_meta("category", "road")
	_save_kit(root, "road_tile")

func plaza_kit() -> void:
	var root := Node3D.new()
	root.name = "Kit_plaza_tile"
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	mi.mesh = plane
	var m := mat_from_tex("ground_dm04.png")
	m.uv1_scale = Vector3(10, 10, 1)
	mi.set_surface_override_material(0, m)
	root.add_child(mi)
	mi.owner = root
	var body := StaticBody3D.new()
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	col.shape = box
	col.position.y = -0.1
	body.add_child(col)
	col.owner = root
	root.set_meta("kit_id", "plaza_tile")
	root.set_meta("category", "plaza")
	_save_kit(root, "plaza_tile")

func _save_kit(root: Node3D, id: String) -> void:
	var packed := PackedScene.new()
	packed.pack(root)
	var path := KIT_DIR + id + ".tscn"
	var err := ResourceSaver.save(packed, path)
	print("KIT ", id, " ", err, " ", path)
	root.free()

func build_mesh_kit(def: Dictionary) -> Dictionary:
	var mesh_path := MESH_DIR + String(def.mesh)
	if not FileAccess.file_exists(mesh_path) and not ResourceLoader.exists(mesh_path):
		# Absolute fallback during headless before import
		var abs_path := "/home/gamedev/LunexMMOKit/client/world/library/meshes/" + String(def.mesh)
		if not FileAccess.file_exists(abs_path):
			print("SKIP_MISSING ", def.id)
			return {"id": def.id, "error": "missing_mesh"}
	var model := load_glb_root(MESH_DIR + String(def.mesh))
	if model == null:
		# try absolute via FileAccess path for GLTF
		var abs_path := "/home/gamedev/LunexMMOKit/client/world/library/meshes/" + String(def.mesh)
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(abs_path, state) != OK:
			print("SKIP_LOAD ", def.id)
			return {"id": def.id, "error": "load_fail"}
		model = doc.generate_scene(state) as Node3D
	var root := Node3D.new()
	root.name = "Kit_" + String(def.id)
	self.root.add_child(root)
	root.add_child(model)
	model.owner = root
	# Flatten imported FBX basis for kit reuse; yaw is composition-time.
	model.rotation_degrees = Vector3(0, float(def.get("yaw", 0.0)), 0)
	var special := String(def.get("special", ""))
	var mat: Material
	if special == "crystal":
		mat = crystal_mat()
	elif special == "water":
		mat = water_mat()
		model.rotation = Vector3.ZERO
	else:
		mat = mat_from_tex(String(def.get("tex", "")))
	await process_frame
	var bounds := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for i in range(mi.mesh.get_surface_count()):
			mi.set_surface_override_material(i, mat)
		var b: AABB = mi.global_transform * mi.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
		mi.owner = root
	# Sit on ground: shift so min Y = 0 in kit space
	if not first:
		model.position.y -= bounds.position.y
		await process_frame
		bounds = AABB()
		first = true
		for mi2 in model.find_children("*", "MeshInstance3D", true, false):
			if mi2.mesh == null:
				continue
			var b2: AABB = mi2.global_transform * mi2.get_aabb()
			bounds = b2 if first else bounds.merge(b2)
			first = false
	# Simple collision box from bounds
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	if not first:
		box.size = Vector3(maxf(bounds.size.x, 1.0), maxf(bounds.size.y, 0.5), maxf(bounds.size.z, 1.0))
		col.position = Vector3(bounds.get_center().x - model.position.x, box.size.y * 0.5, bounds.get_center().z - model.position.z)
	else:
		box.size = Vector3(2, 2, 2)
	col.shape = box
	body.add_child(col)
	col.owner = root
	root.set_meta("kit_id", String(def.id))
	root.set_meta("category", String(def.category))
	root.set_meta("source_id", String(def.source))
	root.get_parent().remove_child(root)
	_save_kit(root, String(def.id))
	return {"id": def.id, "category": def.category, "source": def.source, "path": KIT_DIR + String(def.id) + ".tscn", "height": bounds.size.y if not first else 0.0}

func run():
	DirAccess.make_dir_recursive_absolute("/home/gamedev/LunexMMOKit/client/world/library/kits")
	ground_kit()
	road_kit()
	plaza_kit()
	var report: Array = [
		{"id": "ground_tile", "category": "terrain"},
		{"id": "road_tile", "category": "road"},
		{"id": "plaza_tile", "category": "plaza"},
	]
	for def in KIT_DEFS:
		report.append(await build_mesh_kit(def))
	var f := FileAccess.open(OUT_META, FileAccess.WRITE)
	f.store_string(JSON.stringify({"kits": report}, "\t"))
	f.close()
	print("KITS_DONE ", report.size())
	quit(0)
