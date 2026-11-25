extends SceneTree
## WORLD-DESIGN-002: rebuild kits with embedded meshes + Darklord textures.
## Fixes: (1) water FBX was ~400m blue plane; (2) many kits packed without MeshInstance owners.
const MESH_DIR := "/home/gamedev/LunexMMOKit/client/world/library/meshes/"
const TEX_DIR := "res://world/library/textures/"
const KIT_DIR := "res://world/library/kits/"
const OUT_META := "/home/gamedev/darklord-dgi/environment-kits.json"

var KIT_DEFS := [
	{"id": "gate_main", "category": "gate", "mesh": "gate_main.glb", "tex": "build_jz03.png", "source": "cs_yw_xsc_chengmengqian02"},
	{"id": "palace_01", "category": "palace", "mesh": "palace_gonghui01.glb", "tex": "build_jz02.png", "source": "cs_zhucheng_gonghui01"},
	{"id": "palace_02", "category": "palace", "mesh": "palace_gonghui02.glb", "tex": "build_jz01.png", "source": "cs_zhucheng_gonghui02"},
	{"id": "arch_jz01", "category": "building", "mesh": "arch_jz01.glb", "tex": "build_jz01.png", "source": "cs_zhucheng_jz01"},
	{"id": "arch_jz02", "category": "building", "mesh": "arch_jz02.glb", "tex": "build_jz03.png", "source": "cs_zhucheng_jz02"},
	{"id": "arch_jz03", "category": "building", "mesh": "arch_jz03.glb", "tex": "build_jz04.png", "source": "cs_zhucheng_jz03"},
	{"id": "house_01", "category": "building", "mesh": "house_fangzi01.glb", "tex": "build_jz01.png", "source": "cs_zhucheng_fangzi01"},
	{"id": "house_02", "category": "building", "mesh": "house_fangzi02.glb", "tex": "build_jz02.png", "source": "cs_zhucheng_fangzi02"},
	{"id": "house_03", "category": "building", "mesh": "house_fangzi03.glb", "tex": "build_jz05.png", "source": "cs_zhucheng_fangzi03"},
	{"id": "shop_01", "category": "building", "mesh": "shop_zawu01.glb", "tex": "build_jz04.png", "source": "cs_zhucheng_zawu01"},
	{"id": "shop_04", "category": "building", "mesh": "shop_zawu04.glb", "tex": "build_jz05.png", "source": "cs_zhucheng_zawu04"},
	{"id": "shop_07", "category": "building", "mesh": "shop_zawu07.glb", "tex": "build_jz02.png", "source": "cs_zhucheng_zawu07"},
	{"id": "bridge_01", "category": "bridge", "mesh": "bridge_qiao.glb", "tex": "wall_qiang01.png", "source": "FB_14_qiao"},
	{"id": "fountain_01", "category": "fountain", "mesh": "fountain_penquan.glb", "tex": "build_jz03.png", "source": "cs_zhucheng_penquan"},
	{"id": "statue_01", "category": "statue", "mesh": "statue_01.glb", "tex": "build_jz01.png", "source": "cs_zhucheng_diaoxiang01"},
	{"id": "statue_base", "category": "statue", "mesh": "statue_base_01.glb", "tex": "wall_qiang01.png", "source": "cs_zhucheng_diaoxiangtai01"},
	{"id": "crystal_01", "category": "crystal", "mesh": "crystal_mesh.glb", "tex": "", "source": "cs_zhucheng_shuijing", "special": "crystal"},
	{"id": "tree_01", "category": "tree", "mesh": "tree_01.glb", "tex": "blossom.png", "source": "cs_zhucheng_shu01"},
	{"id": "tree_plant", "category": "tree", "mesh": "tree_plant.glb", "tex": "blossom.png", "source": "cs_zhucheng_zhiwu01"},
	{"id": "bush_01", "category": "bush", "mesh": "bush_01.glb", "tex": "splat_grass.png", "source": "cs_zhucheng_guanmu01"},
	{"id": "lamp_01", "category": "prop", "mesh": "lamp_01.glb", "tex": "build_jz04.png", "source": "cs_zhucheng_ludeng01"},
	{"id": "rock_01", "category": "rock", "mesh": "rock_01.glb", "tex": "splat_dirt.png", "source": "cs_haitan_shitou01"},
	{"id": "rock_02", "category": "rock", "mesh": "rock_02.glb", "tex": "splat_sand.png", "source": "cs_haitan_shitou02"},
]

func _initialize():
	call_deferred("run")

func own_tree(n: Node, owner: Node) -> void:
	n.owner = owner
	for c in n.get_children():
		own_tree(c, owner)

func mat_tex(path: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if path != "" and ResourceLoader.exists(TEX_DIR + path):
		m.albedo_texture = load(TEX_DIR + path)
	else:
		m.albedo_color = Color(0.62, 0.58, 0.5)
	m.roughness = 0.82
	m.metallic = 0.0
	return m

func crystal_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	# Prefer original effect spark texture over flat cyan albedo.
	if ResourceLoader.exists(TEX_DIR + "crystal_fx.png"):
		m.albedo_texture = load(TEX_DIR + "crystal_fx.png")
		m.albedo_color = Color(0.75, 0.85, 1.0, 0.85)
	else:
		m.albedo_color = Color(0.65, 0.8, 0.95, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.35, 0.55, 0.9)
	m.emission_energy_multiplier = 0.85
	m.roughness = 0.28
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func water_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(TEX_DIR + "water_zhucheng.png"):
		m.albedo_texture = load(TEX_DIR + "water_zhucheng.png")
	elif ResourceLoader.exists(TEX_DIR + "water_main.png"):
		m.albedo_texture = load(TEX_DIR + "water_main.png")
	m.albedo_color = Color(0.55, 0.7, 0.85, 0.72)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.12
	m.metallic = 0.05
	m.uv1_scale = Vector3(4, 4, 1)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func save_plane_kit(id: String, category: String, tex: String, size: Vector2, uv: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Kit_" + id
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = size
	mi.mesh = plane
	var m := mat_tex(tex)
	m.uv1_scale = uv
	mi.set_surface_override_material(0, m)
	root.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	col.shape = box
	col.position.y = -0.1
	body.add_child(col)
	own_tree(root, root)
	root.set_meta("kit_id", id)
	root.set_meta("category", category)
	_save(root, id)

func save_water_kit() -> void:
	# Do NOT use Darklord water FBX: local AABB ~400x400, fills scene with solid blue.
	var root := Node3D.new()
	root.name = "Kit_water_01"
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(28, 18)
	mi.mesh = plane
	mi.set_surface_override_material(0, water_mat())
	root.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	# No walk collision on water surface — thin box below for containment optional
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(28, 0.5, 18)
	col.shape = box
	col.position.y = -0.4
	body.add_child(col)
	own_tree(root, root)
	root.set_meta("kit_id", "water_01")
	root.set_meta("category", "water")
	root.set_meta("source_id", "cs_yw_zhucheng_water+texture")
	_save(root, "water_01")

func save_sidewalk_kit() -> void:
	save_plane_kit("sidewalk_tile", "road", "sidewalk.png", Vector2(6, 20), Vector3(2, 6, 1))

func _save(root: Node3D, id: String) -> void:
	var packed := PackedScene.new()
	var err_pack := packed.pack(root)
	var err := ResourceSaver.save(packed, KIT_DIR + id + ".tscn")
	print("KIT ", id, " pack=", err_pack, " save=", err)
	root.free()

func load_model(abs_glb: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(abs_glb, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D

func build_mesh_kit(def: Dictionary) -> Dictionary:
	var abs_glb := MESH_DIR + String(def.mesh)
	if not FileAccess.file_exists(abs_glb):
		print("SKIP_MISSING ", def.id, " ", abs_glb)
		return {"id": def.id, "error": "missing"}
	var model := load_model(abs_glb)
	if model == null:
		print("SKIP_LOAD ", def.id)
		return {"id": def.id, "error": "load"}
	var root := Node3D.new()
	root.name = "Kit_" + String(def.id)
	self.root.add_child(root)
	root.add_child(model)
	# Drop imported local transforms that offset kits into the sky / far away.
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO
	model.scale = Vector3.ONE
	for n in model.find_children("*", "Node3D", true, false):
		# Keep relative hierarchy but zero extreme root-level FBX axis nodes later via bounds sit
		pass
	await process_frame
	var special := String(def.get("special", ""))
	var mat: Material = crystal_mat() if special == "crystal" else mat_tex(String(def.get("tex", "")))
	var mesh_count := 0
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		# Embed mesh + bake material onto surfaces (override alone was lost on some kits).
		var mesh: Mesh = mi.mesh.duplicate()
		for i in range(mesh.get_surface_count()):
			if mesh is ArrayMesh:
				(mesh as ArrayMesh).surface_set_material(i, mat)
			mi.set_surface_override_material(i, mat)
		mi.mesh = mesh
		mesh_count += 1
	if mesh_count == 0:
		print("SKIP_EMPTY ", def.id)
		root.free()
		return {"id": def.id, "error": "no_mesh"}
	await process_frame
	# Bounds in kit space
	var bounds := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var b: AABB = mi.global_transform * mi.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	if not first:
		# Reject absurd kits (corrupt/oversized import)
		if bounds.size.x > 120.0 or bounds.size.z > 120.0 or bounds.size.y > 80.0:
			print("SKIP_HUGE ", def.id, " ", bounds.size)
			# Still keep if building intentionally large (jz01) — clamp note
			if bounds.size.x > 250.0 or bounds.size.z > 250.0:
				root.free()
				return {"id": def.id, "error": "huge", "size": [bounds.size.x, bounds.size.y, bounds.size.z]}
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
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	if not first:
		box.size = Vector3(maxf(bounds.size.x, 0.8), maxf(bounds.size.y, 0.5), maxf(bounds.size.z, 0.8))
		col.position = Vector3(bounds.get_center().x, box.size.y * 0.5, bounds.get_center().z)
	else:
		box.size = Vector3(2, 2, 2)
	col.shape = box
	body.add_child(col)
	own_tree(root, root)
	root.set_meta("kit_id", String(def.id))
	root.set_meta("category", String(def.category))
	root.set_meta("source_id", String(def.source))
	root.get_parent().remove_child(root)
	_save(root, String(def.id))
	return {"id": def.id, "category": def.category, "source": def.source, "meshes": mesh_count, "size": [bounds.size.x, bounds.size.y, bounds.size.z] if not first else []}

func run():
	DirAccess.make_dir_recursive_absolute("/home/gamedev/LunexMMOKit/client/world/library/kits")
	# Import new water textures
	await process_frame
	save_plane_kit("ground_tile", "terrain", "splat_grass.png", Vector2(20, 20), Vector3(8, 8, 1))
	save_plane_kit("road_tile", "road", "ground_dm02.png", Vector2(12, 20), Vector3(4, 6, 1))
	save_plane_kit("plaza_tile", "plaza", "ground_dm04.png", Vector2(40, 40), Vector3(10, 10, 1))
	save_sidewalk_kit()
	save_water_kit()
	var report: Array = [
		{"id": "ground_tile"}, {"id": "road_tile"}, {"id": "plaza_tile"},
		{"id": "sidewalk_tile"}, {"id": "water_01"},
	]
	for def in KIT_DEFS:
		report.append(await build_mesh_kit(def))
	var f := FileAccess.open(OUT_META, FileAccess.WRITE)
	f.store_string(JSON.stringify({"note": "rebuilt after blue-water audit", "kits": report}, "\t"))
	f.close()
	var ok := 0
	for r in report:
		if typeof(r) == TYPE_DICTIONARY and not r.has("error"):
			ok += 1
	print("KITS_DONE ok=", ok, " total=", report.size())
	quit(0)
