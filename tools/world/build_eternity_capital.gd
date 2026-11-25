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

func run():
	_city = Node3D.new()
	_city.name = "EternityCapital"
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

	# --- Palace (textured gonghui) ---
	var palace := district("06_Palace")
	inst("palace_01", palace, Vector3(0, 0.05, 48), 180.0, Vector3(1.15, 1.15, 1.15))
	inst("house_01", palace, Vector3(-20, 0.05, 42), 150.0)
	inst("house_02", palace, Vector3(20, 0.05, 42), -150.0)
	inst("statue_01", palace, Vector3(-7, 0.05, 36), 0.0)
	inst("statue_01", palace, Vector3(7, 0.05, 36), 0.0)
	inst("lamp_01", palace, Vector3(0, 0.05, 34))

	var market := district("07_Market")
	for i in range(4):
		inst(["shop_01", "shop_04", "shop_07", "shop_01"][i], market, Vector3(34 + (i % 2) * 12.0, 0.05, -8 + int(i / 2) * 12.0), -90.0)
	inst("lamp_01", market, Vector3(28, 0.05, 0))
	inst("tree_01", market, Vector3(40, 0.05, 10), 30.0)

	var craft := district("08_Craft")
	for i in range(4):
		inst(["shop_07", "shop_04", "shop_01", "shop_07"][i], craft, Vector3(-34 - (i % 2) * 12.0, 0.05, -8 + int(i / 2) * 12.0), 90.0)
	inst("rock_01", craft, Vector3(-46, 0.05, 6), 25.0)
	inst("lamp_01", craft, Vector3(-28, 0.05, 0))

	var quest := district("09_QuestNpc")
	inst("house_03", quest, Vector3(-32, 0.05, 24), 35.0)
	inst("lamp_01", quest, Vector3(-24, 0.05, 18))
	for i in range(3):
		var m := MeshInstance3D.new()
		m.name = "QuestMarker_" + str(i)
		var sphere := SphereMesh.new()
		sphere.radius = 0.4
		sphere.height = 0.8
		m.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.82, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.15)
		mat.emission_energy_multiplier = 1.0
		m.set_surface_override_material(0, mat)
		quest.add_child(m)
		m.position = Vector3(-22 - i * 2.5, 1.1, 18 + i * 1.5)
		m.owner = _city

	var portals := district("10_Portals")
	# Portal frames use arch pieces + soft crystal, not giant cyan blobs
	inst("arch_jz03", portals, Vector3(28, 0.05, 22), 90.0, Vector3(0.7, 0.7, 0.7))
	inst("arch_jz03", portals, Vector3(-28, 0.05, 22), -90.0, Vector3(0.7, 0.7, 0.7))
	inst("crystal_01", portals, Vector3(28, 0.05, 22), 0.0, Vector3(0.35, 0.55, 0.35))
	inst("crystal_01", portals, Vector3(-28, 0.05, 22), 0.0, Vector3(0.35, 0.55, 0.35))
	inst("lamp_01", portals, Vector3(28, 0.05, 28))
	inst("lamp_01", portals, Vector3(-28, 0.05, 28))

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
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.52, 0.66, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.8, 0.9)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.95
	e.fog_enabled = true
	e.fog_light_color = Color(0.6, 0.7, 0.82)
	e.fog_density = 0.0015
	e.fog_aerial_perspective = 0.4
	e.glow_enabled = false
	e.ssao_enabled = false
	# Soft sky gradient via sky resource if available
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
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
