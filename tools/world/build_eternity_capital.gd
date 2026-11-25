extends SceneTree
## WORLD-DESIGN-002: beautiful hand-authored Eternity Capital (editable kit instances).
const KIT := "res://world/library/kits/"
const OUT := "res://world/locations/eternity_capital/eternity_capital.tscn"

var _city: Node3D

func _initialize():
	call_deferred("run")

func inst(id: String, parent: Node3D, pos: Vector3, yaw_deg: float = 0.0, scale := Vector3.ONE) -> Node3D:
	var path := KIT + id + ".tscn"
	if not ResourceLoader.exists(path):
		print("MISSING_KIT ", id)
		return null
	var n: Node3D = load(path).instantiate()
	n.name = id + "_" + str(parent.get_child_count())
	parent.add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	n.scale = scale
	_own(n, _city)
	return n

func _own(n: Node, owner: Node) -> void:
	n.owner = owner
	for c in n.get_children():
		_own(c, owner)

func district(name: String) -> Node3D:
	var d := Node3D.new()
	d.name = name
	_city.add_child(d)
	d.owner = _city
	return d

func _spawn_npc(parent: Node3D, pos: Vector3, yaw: float, npc_name: String) -> void:
	var npc := Node3D.new()
	npc.name = npc_name
	parent.add_child(npc)
	npc.position = pos
	npc.rotation_degrees.y = yaw
	npc.set_meta("npc_role", "quest")
	npc.set_meta("editable", true)
	# Stable ID survives transforms; quests bind to this, not node path/coords.
	npc.set_meta("stable_id", "npc_" + npc_name.to_lower())
	# Prefer real class mesh if export exists; else capsule placeholder.
	var body := Node3D.new()
	body.name = "Visual"
	npc.add_child(body)
	var glb_path := "/home/gamedev/darklord-dgi/exports/10001.glb"
	var loaded := false
	if FileAccess.file_exists(glb_path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(glb_path, state) == OK:
			var model := doc.generate_scene(state) as Node3D
			if model:
				body.add_child(model)
				model.scale = Vector3(1, 1, 1)
				loaded = true
	if not loaded:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.5
		mi.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.55, 0.7)
		mi.set_surface_override_material(0, mat)
		mi.position.y = 0.9
		body.add_child(mi)
	_own(npc, _city)

func run():
	# WORLD-EDITOR-003: never clobber owner-edited capital without explicit force.
	var out_abs := ProjectSettings.globalize_path(OUT)
	var lock_path := out_abs.get_basename() + ".owner.lock"
	var force := "--force-overwrite" in OS.get_cmdline_user_args() or "--force-overwrite" in OS.get_cmdline_args()
	if FileAccess.file_exists(lock_path) and not force:
		print("OWNER_LOCK refuse overwrite ", lock_path, " (pass --force-overwrite to bake generated)")
		quit(2)
		return
	if FileAccess.file_exists(out_abs):
		var existing := load(OUT) as PackedScene
		if existing:
			var probe: Node = existing.instantiate()
			if probe and probe.has_meta("owner_edited") and bool(probe.get_meta("owner_edited")) and not force:
				print("OWNER_EDITED refuse overwrite ", OUT)
				probe.free()
				quit(2)
				return
			if probe:
				probe.free()
	_city = Node3D.new()
	_city.name = "EternityCapital"
	_city.set_meta("location_id", "eternity_capital")
	_city.set_meta("location_revision", 1)
	root.add_child(_city)

	# --- Ground canvas ---
	var land := district("01_Landscape")
	for x in range(-5, 6):
		for z in range(-6, 6):
			if abs(x) <= 1 and abs(z) <= 1:
				continue
			if x == 0 and z >= -4 and z <= 2:
				continue
			inst("ground_tile", land, Vector3(x * 20.0, 0.0, z * 20.0))

	var roads := district("02_Avenue")
	for z in range(-4, 3):
		inst("road_tile", roads, Vector3(0, 0.02, z * 20.0))
		inst("sidewalk_tile", roads, Vector3(-9.0, 0.04, z * 20.0))
		inst("sidewalk_tile", roads, Vector3(9.0, 0.04, z * 20.0))

	# --- Plaza ---
	var plaza := district("03_CentralPlaza")
	inst("plaza_tile", plaza, Vector3(0, 0.03, 0))
	# Monument: fountain + statues (crystal kept small — large emission reads as “missing blue”)
	inst("fountain_01", plaza, Vector3(0, 0.05, 0), 0.0, Vector3(1.25, 1.25, 1.25))
	inst("crystal_01", plaza, Vector3(0, 2.2, 0), 0.0, Vector3(0.28, 0.45, 0.28))
	inst("statue_01", plaza, Vector3(-11, 0.05, -9), 20.0)
	inst("statue_01", plaza, Vector3(11, 0.05, -9), -20.0)
	inst("statue_base", plaza, Vector3(0, 0.05, 12), 0.0, Vector3(0.9, 0.9, 0.9))
	inst("lamp_01", plaza, Vector3(-13, 0.05, 0))
	inst("lamp_01", plaza, Vector3(13, 0.05, 0))
	inst("lamp_01", plaza, Vector3(0, 0.05, -13))
	inst("bush_01", plaza, Vector3(-16, 0.05, 8), 10.0)
	inst("bush_01", plaza, Vector3(16, 0.05, 8), -10.0)
	inst("crate_01", plaza, Vector3(-8, 0.05, 6), 15.0, Vector3(1.2, 1.2, 1.2))
	inst("barrel_01", plaza, Vector3(8, 0.05, 5), -10.0, Vector3(1.2, 1.2, 1.2))
	inst("flag_01", plaza, Vector3(-6, 0.05, -12), 0.0)
	inst("flag_01", plaza, Vector3(6, 0.05, -12), 0.0)
	_spawn_npc(plaza, Vector3(-4, 0.05, 4), 160.0, "PlazaGuard_L")
	_spawn_npc(plaza, Vector3(4, 0.05, 4), -160.0, "PlazaGuard_R")
	_spawn_npc(plaza, Vector3(0, 0.05, 8), 180.0, "PlazaElder")

	# --- Gate (textured) ---
	var gates := district("04_MainGate")
	inst("gate_main", gates, Vector3(0, 0.05, -78), 0.0, Vector3(1.35, 1.35, 1.35))
	inst("lamp_01", gates, Vector3(-10, 0.05, -70))
	inst("lamp_01", gates, Vector3(10, 0.05, -70))
	inst("statue_01", gates, Vector3(-14, 0.05, -72), 15.0, Vector3(0.9, 0.9, 0.9))
	inst("statue_01", gates, Vector3(14, 0.05, -72), -15.0, Vector3(0.9, 0.9, 0.9))

	# --- Street houses (best-looking kits only) ---
	var street := district("05_CentralStreet")
	var west := ["house_01", "house_02", "house_03", "shop_01", "house_02", "shop_07", "house_01"]
	var east := ["house_02", "house_03", "house_01", "shop_04", "house_03", "shop_01", "house_02"]
	for i in range(west.size()):
		var z := -64.0 + i * 9.5
		inst(west[i], street, Vector3(-15, 0.05, z), 90.0, Vector3(1.05, 1.05, 1.05))
		inst(east[i], street, Vector3(15, 0.05, z), -90.0, Vector3(1.05, 1.05, 1.05))
		inst("lamp_01", street, Vector3(-7.5, 0.05, z + 2.0))
		inst("lamp_01", street, Vector3(7.5, 0.05, z + 2.0))
		if i % 2 == 0:
			inst("bush_01", street, Vector3(-21, 0.05, z), float(i * 12))
			inst("tree_plant", street, Vector3(22, 0.05, z + 1.0), float(i * 18))
		# Street clutter
		inst(["barrel_01", "barrel_02", "crate_01"][i % 3], street, Vector3(-11.5, 0.05, z + 3.5), float(i * 25), Vector3(1.2, 1.2, 1.2))
		inst(["crate_02", "crate_01", "barrel_01"][i % 3], street, Vector3(11.5, 0.05, z + 1.5), float(i * -20), Vector3(1.15, 1.15, 1.15))
		if i % 3 == 0:
			inst("flag_01", street, Vector3(-8.5, 0.05, z - 2.0), 90.0, Vector3(1.1, 1.1, 1.1))
			inst("flag_01", street, Vector3(8.5, 0.05, z - 2.0), -90.0, Vector3(1.1, 1.1, 1.1))
		if i % 2 == 1:
			inst(["stall_01", "stall_02"][i % 2], street, Vector3(-10.5, 0.05, z + 5.0), 90.0, Vector3(0.85, 0.85, 0.85))
			inst(["stall_02", "stall_03"][i % 2], street, Vector3(10.5, 0.05, z + 5.0), -90.0, Vector3(0.85, 0.85, 0.85))

	# --- Palace (textured gonghui) ---
	var palace := district("06_Palace")
	inst("palace_01", palace, Vector3(0, 0.05, 48), 180.0, Vector3(1.15, 1.15, 1.15))
	inst("house_01", palace, Vector3(-20, 0.05, 42), 150.0)
	inst("house_02", palace, Vector3(20, 0.05, 42), -150.0)
	inst("statue_01", palace, Vector3(-7, 0.05, 36), 0.0)
	inst("statue_01", palace, Vector3(7, 0.05, 36), 0.0)
	inst("lamp_01", palace, Vector3(0, 0.05, 34))

	var market := district("07_Market")
	# Paved market yard — without this the district sat on washed landscape and looked “gray / no textures”.
	inst("market_tile", market, Vector3(36, 0.03, 0))
	inst("market_tile", market, Vector3(36, 0.03, -20), 0.0, Vector3(0.85, 1.0, 0.85))
	inst("sidewalk_tile", market, Vector3(24, 0.04, -4))
	inst("sidewalk_tile", market, Vector3(24, 0.04, 8))
	for i in range(4):
		inst(["shop_01", "shop_04", "shop_07", "shop_01"][i], market, Vector3(34 + (i % 2) * 12.0, 0.05, -8 + int(i / 2) * 12.0), -90.0)
		inst(["stall_01", "stall_02", "stall_03"][i % 3], market, Vector3(28 + (i % 2) * 6.0, 0.05, -12 + i * 5.0), -90.0, Vector3(1.2, 1.2, 1.2))
		inst(["crate_01", "barrel_01", "crate_02"][i % 3], market, Vector3(30 + i * 2.0, 0.05, 2.0), float(i * 15), Vector3(1.3, 1.3, 1.3))
	inst("lamp_01", market, Vector3(28, 0.05, 0))
	inst("tree_01", market, Vector3(40, 0.05, 10), 30.0)
	inst("bush_01", market, Vector3(44, 0.05, 4), 15.0)
	inst("flag_01", market, Vector3(26, 0.05, -4), 0.0)

	var craft := district("08_Craft")
	inst("market_tile", craft, Vector3(-36, 0.03, 0))
	inst("sidewalk_tile", craft, Vector3(-24, 0.04, -4))
	for i in range(4):
		inst(["shop_07", "shop_04", "shop_01", "shop_07"][i], craft, Vector3(-34 - (i % 2) * 12.0, 0.05, -8 + int(i / 2) * 12.0), 90.0)
		inst(["barrel_02", "crate_01", "barrel_01"][i % 3], craft, Vector3(-30 - i * 2.5, 0.05, 2 + i), float(i * 40), Vector3(1.25, 1.25, 1.25))
	inst("rock_01", craft, Vector3(-46, 0.05, 6), 25.0)
	inst("lamp_01", craft, Vector3(-28, 0.05, 0))
	inst("stall_03", craft, Vector3(-26, 0.05, -4), 90.0, Vector3(1.2, 1.2, 1.2))

	var quest := district("09_QuestNpc")
	inst("house_03", quest, Vector3(-32, 0.05, 24), 35.0)
	inst("lamp_01", quest, Vector3(-24, 0.05, 18))
	inst("flag_01", quest, Vector3(-20, 0.05, 16), 20.0)
	for i in range(3):
		var m := MeshInstance3D.new()
		m.name = "QuestMarker_" + str(i)
		var sphere := SphereMesh.new()
		sphere.radius = 0.35
		sphere.height = 0.7
		m.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.82, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.15)
		mat.emission_energy_multiplier = 1.0
		m.set_surface_override_material(0, mat)
		quest.add_child(m)
		m.position = Vector3(-22 - i * 2.5, 2.4, 18 + i * 1.5)
		m.owner = _city
		_spawn_npc(quest, Vector3(-22 - i * 2.5, 0.05, 18 + i * 1.5), 180.0 + i * 20.0, "QuestGiver_" + str(i))

	var portals := district("10_Portals")
	# Portal frames use arch pieces + soft crystal, not giant cyan blobs
	inst("arch_jz03", portals, Vector3(28, 0.05, 22), 90.0, Vector3(0.7, 0.7, 0.7))
	inst("arch_jz03", portals, Vector3(-28, 0.05, 22), -90.0, Vector3(0.7, 0.7, 0.7))
	inst("crystal_01", portals, Vector3(28, 0.05, 22), 0.0, Vector3(0.35, 0.55, 0.35))
	inst("crystal_01", portals, Vector3(-28, 0.05, 22), 0.0, Vector3(0.35, 0.55, 0.35))
	inst("lamp_01", portals, Vector3(28, 0.05, 28))
	inst("lamp_01", portals, Vector3(-28, 0.05, 28))
	# East gate → Ashen Outskirts (chapter 1). stable_id for quests/portals.
	var ashen := Node3D.new()
	ashen.name = "Portal_AshenGate"
	ashen.set_meta("stable_id", "portal_ashen_gate")
	ashen.set_meta("portal_id", "ashen_gate")
	ashen.set_meta("target_location", "ashen_outskirts")
	ashen.set_meta("target_scene", "res://world/locations/ashen_outskirts/ashen_play.tscn")
	portals.add_child(ashen)
	ashen.position = Vector3(28, 0.05, 22)
	ashen.owner = _city

	var park := district("11_Park")
	for i in range(10):
		var ang := i * TAU / 10.0
		inst(["tree_01", "tree_plant"][i % 2], park, Vector3(46 + cos(ang) * 9.0, 0.05, 28 + sin(ang) * 9.0), rad_to_deg(ang))
		inst("bush_01", park, Vector3(46 + cos(ang + 0.3) * 5.0, 0.05, 28 + sin(ang + 0.3) * 5.0))
	inst("fountain_01", park, Vector3(46, 0.05, 28), 0.0, Vector3(0.75, 0.75, 0.75))

	var water := district("12_Water")
	# Pond + bridge OFF the main avenue so the elevated deck does not float over the street.
	inst("water_01", water, Vector3(38, -0.12, -18), 0.0, Vector3(1.1, 1.0, 1.1))
	inst("bridge_01", water, Vector3(38, -1.2, -18), 0.0, Vector3(0.85, 0.85, 0.85))
	inst("rock_01", water, Vector3(30, 0.05, -22), 12.0)
	inst("rock_02", water, Vector3(46, 0.05, -14), -18.0)
	inst("bush_01", water, Vector3(32, 0.05, -12))
	inst("tree_01", water, Vector3(48, 0.05, -24), 40.0)
	inst("lamp_01", water, Vector3(34, 0.05, -10))

	var far := district("13_Skyline")
	for i in range(8):
		inst("tree_01", far, Vector3(-75 + i * 6.0, 0.05, 55), float(i * 20))
		inst("tree_plant", far, Vector3(55 + i * 5.0, 0.05, -55), float(i * 15))
	inst("rock_02", far, Vector3(-90, 0.2, 20), 30.0, Vector3(3.0, 2.2, 3.0))
	inst("rock_01", far, Vector3(90, 0.2, -10), -40.0, Vector3(2.8, 2.0, 2.8))
	inst("house_01", far, Vector3(-55, 0.05, 30), 40.0, Vector3(1.2, 1.2, 1.2))
	inst("house_02", far, Vector3(55, 0.05, 25), -35.0, Vector3(1.2, 1.2, 1.2))

	# --- Art direction ---
	var art := district("14_ArtDirection")
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_color = Color(0.62, 0.68, 0.78)
	e.ambient_light_energy = 0.28
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.88
	e.fog_enabled = true
	e.fog_light_color = Color(0.55, 0.65, 0.78)
	e.fog_density = 0.0012
	e.fog_aerial_perspective = 0.35
	e.glow_enabled = false
	e.ssao_enabled = false
	# Soft sky gradient via sky resource if available
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.48, 0.82)
	sky_mat.sky_horizon_color = Color(0.72, 0.78, 0.88)
	sky_mat.ground_bottom_color = Color(0.45, 0.4, 0.35)
	sky_mat.ground_horizon_color = Color(0.65, 0.62, 0.55)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55
	env.environment = e
	art.add_child(env)
	env.owner = _city

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-40, -32, 0)
	sun.light_energy = 0.9
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260.0
	art.add_child(sun)
	sun.owner = _city

	var fill := OmniLight3D.new()
	fill.name = "CrystalFill"
	fill.position = Vector3(0, 6.5, 0)
	fill.light_color = Color(0.45, 0.65, 1.0)
	fill.light_energy = 0.85
	fill.omni_range = 22.0
	art.add_child(fill)
	fill.owner = _city

	var gate_fill := OmniLight3D.new()
	gate_fill.name = "GateFill"
	gate_fill.position = Vector3(0, 5.5, -78)
	gate_fill.light_color = Color(1.0, 0.88, 0.6)
	gate_fill.light_energy = 0.75
	gate_fill.omni_range = 20.0
	art.add_child(gate_fill)
	gate_fill.owner = _city

	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0, 0.6, -58)
	_city.add_child(spawn)
	spawn.owner = _city

	DirAccess.make_dir_recursive_absolute("/home/gamedev/LunexMMOKit/client/world/locations/eternity_capital")
	var packed := PackedScene.new()
	packed.pack(_city)
	var err := ResourceSaver.save(packed, OUT)
	print("CAPITAL_SAVE ", err, " districts ", _city.get_child_count())
	_city.free()
	quit(0 if err == OK else 1)
