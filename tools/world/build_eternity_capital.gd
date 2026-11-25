extends SceneTree
## WORLD-DESIGN-002: compose hand-authored Eternity Capital from library kits.
const KIT := "res://world/library/kits/"
const OUT := "res://world/locations/eternity_capital/eternity_capital.tscn"
const ABS_OUT := "/home/gamedev/LunexMMOKit/client/world/locations/eternity_capital/eternity_capital.tscn"

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
	n.owner = _city
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	n.scale = scale
	_mark_owners(n, _city)
	return n

func _mark_owners(n: Node, owner: Node) -> void:
	n.owner = owner
	for c in n.get_children():
		_mark_owners(c, owner)

var _city: Node3D

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

	# --- Landscape ---
	var land := district("01_Landscape")
	for x in range(-6, 7):
		for z in range(-7, 8):
			# plaza hole
			if abs(x) <= 1 and abs(z) <= 1:
				continue
			# road strip along Z at x=0
			if x == 0 and z >= -4 and z <= 3:
				continue
			var g := inst("ground_tile", land, Vector3(x * 20.0, 0.0, z * 20.0))
			# Soft height rings for silhouette (no floating props: buildings stay on y≈0 pads)
			if g and (abs(x) >= 5 or abs(z) >= 6):
				g.position.y = 0.35
	# Outer cliff rocks for far plane
	for i in range(10):
		var ang := i * TAU / 10.0
		inst(["rock_01", "rock_02"][i % 2], land, Vector3(cos(ang) * 110.0, 0.4, sin(ang) * 120.0), rad_to_deg(ang), Vector3(2.5, 2.0, 2.5))

	var roads := district("02_Avenue")
	for z in range(-4, 4):
		inst("road_tile", roads, Vector3(0, 0.02, z * 20.0), 0.0)
		# Sidewalks (textured stone) — replaces former “blue strips” which were oversized water mesh
		inst("sidewalk_tile", roads, Vector3(-9.0, 0.03, z * 20.0), 0.0)
		inst("sidewalk_tile", roads, Vector3(9.0, 0.03, z * 20.0), 0.0)

	var plaza := district("03_CentralPlaza")
	inst("plaza_tile", plaza, Vector3(0, 0.03, 0))
	inst("crystal_01", plaza, Vector3(0, 0.05, 0), 0.0, Vector3(1.4, 1.4, 1.4))
	inst("statue_01", plaza, Vector3(-10, 0.05, -8), 25.0)
	inst("statue_01", plaza, Vector3(10, 0.05, -8), -25.0)
	inst("statue_base", plaza, Vector3(-10, 0.05, 10), 180.0)
	inst("statue_base", plaza, Vector3(10, 0.05, 10), 180.0)
	inst("fountain_01", plaza, Vector3(0, 0.05, 14), 0.0, Vector3(1.2, 1.2, 1.2))
	inst("lamp_01", plaza, Vector3(-14, 0.05, 0), 0.0)
	inst("lamp_01", plaza, Vector3(14, 0.05, 0), 0.0)
	inst("lamp_01", plaza, Vector3(0, 0.05, -14), 0.0)

	var gates := district("04_MainGate")
	inst("gate_main", gates, Vector3(0, 0.05, -78), 0.0, Vector3(1.5, 1.5, 1.5))
	inst("arch_jz02", gates, Vector3(-18, 0.05, -78), 0.0)
	inst("arch_jz03", gates, Vector3(18, 0.05, -78), 0.0)
	inst("lamp_01", gates, Vector3(-8, 0.05, -70), 0.0)
	inst("lamp_01", gates, Vector3(8, 0.05, -70), 0.0)

	var street := district("05_CentralStreet")
	# west facade — denser commercial row
	for i in range(7):
		var z := -62.0 + i * 10.0
		inst(["house_01", "house_02", "house_03", "shop_01"][i % 4], street, Vector3(-14, 0.05, z), 90.0, Vector3(1.1, 1.1, 1.1))
		inst("lamp_01", street, Vector3(-7, 0.05, z + 3.0), 0.0)
		if i % 2 == 0:
			inst("bush_01", street, Vector3(-20, 0.05, z + 2.0), float(i * 15))
	# east facade
	for i in range(7):
		var z := -62.0 + i * 10.0
		inst(["house_02", "house_03", "house_01", "shop_04"][i % 4], street, Vector3(14, 0.05, z), -90.0, Vector3(1.1, 1.1, 1.1))
		inst("lamp_01", street, Vector3(7, 0.05, z + 3.0), 0.0)
		if i % 2 == 1:
			inst("bush_01", street, Vector3(20, 0.05, z + 2.0), float(i * 20))
	# second row depth for silhouette
	for i in range(4):
		var z := -50.0 + i * 14.0
		inst("shop_07", street, Vector3(-28, 0.05, z), 90.0)
		inst("shop_01", street, Vector3(28, 0.05, z), -90.0)

	var palace := district("06_Palace")
	inst("palace_01", palace, Vector3(0, 0.05, 52), 180.0, Vector3(1.3, 1.3, 1.3))
	inst("palace_02", palace, Vector3(-22, 0.05, 48), 160.0)
	inst("palace_02", palace, Vector3(22, 0.05, 48), -160.0)
	inst("arch_jz01", palace, Vector3(0, 0.05, 36), 0.0, Vector3(1.2, 1.2, 1.2))
	inst("statue_01", palace, Vector3(-8, 0.05, 40), 0.0)
	inst("statue_01", palace, Vector3(8, 0.05, 40), 0.0)

	var market := district("07_Market")
	for i in range(4):
		inst(["shop_01", "shop_04", "shop_07"][i % 3], market, Vector3(36 + (i % 2) * 14.0, 0.05, -10 + (i / 2) * 14.0), -90.0)
	inst("lamp_01", market, Vector3(30, 0.05, 0), 0.0)

	var craft := district("08_Craft")
	for i in range(4):
		inst(["shop_07", "shop_04", "shop_01"][i % 3], craft, Vector3(-36 - (i % 2) * 14.0, 0.05, -10 + (i / 2) * 14.0), 90.0)
	inst("rock_01", craft, Vector3(-48, 0.05, 8), 20.0)

	var quest := district("09_QuestNpc")
	inst("arch_jz03", quest, Vector3(-28, 0.05, 22), 45.0)
	inst("house_01", quest, Vector3(-38, 0.05, 28), 30.0)
	inst("lamp_01", quest, Vector3(-24, 0.05, 18), 0.0)
	# markers
	for i in range(3):
		var m := MeshInstance3D.new()
		m.name = "QuestMarker_" + str(i)
		var sphere := SphereMesh.new()
		sphere.radius = 0.45
		sphere.height = 0.9
		m.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.2)
		mat.emission_energy_multiplier = 1.2
		m.set_surface_override_material(0, mat)
		quest.add_child(m)
		m.owner = _city
		m.position = Vector3(-22 - i * 3.0, 1.2, 20 + i * 2.0)

	var portals := district("10_Portals")
	inst("crystal_01", portals, Vector3(28, 0.05, 22), 0.0, Vector3(0.7, 1.1, 0.7))
	inst("crystal_01", portals, Vector3(-8, 0.05, -40), 0.0, Vector3(0.6, 1.0, 0.6))
	inst("arch_jz02", portals, Vector3(28, 0.05, 28), 180.0)

	var park := district("11_Park")
	for i in range(8):
		var ang := i * TAU / 8.0
		inst(["tree_01", "tree_plant"][i % 2], park, Vector3(48 + cos(ang) * 10.0, 0.05, 30 + sin(ang) * 10.0), rad_to_deg(ang))
		inst("bush_01", park, Vector3(48 + cos(ang + 0.4) * 6.0, 0.05, 30 + sin(ang + 0.4) * 6.0), 0.0)
	inst("fountain_01", park, Vector3(48, 0.05, 30), 0.0, Vector3(0.8, 0.8, 0.8))

	var water := district("12_Water")
	# Contained pond south of plaza (kit is a 28x18 textured plane, not FBX ocean)
	inst("water_01", water, Vector3(0, -0.15, -32), 0.0, Vector3(1.0, 1.0, 1.0))
	inst("bridge_01", water, Vector3(0, 0.05, -32), 90.0, Vector3(1.0, 1.0, 1.0))
	inst("rock_01", water, Vector3(-14, 0.05, -36), 10.0)
	inst("rock_02", water, Vector3(14, 0.05, -28), -15.0)
	inst("bush_01", water, Vector3(-16, 0.05, -30), 0.0)
	inst("bush_01", water, Vector3(16, 0.05, -34), 40.0)

	var far := district("13_Skyline")
	inst("arch_jz01", far, Vector3(-70, 0.05, 40), 20.0, Vector3(1.5, 1.5, 1.5))
	inst("arch_jz02", far, Vector3(70, 0.05, 20), -20.0, Vector3(1.5, 1.5, 1.5))
	inst("palace_02", far, Vector3(-60, 0.05, -20), 40.0)
	for i in range(6):
		inst("tree_01", far, Vector3(-80 + i * 5.0, 0.05, 60), float(i * 30))
		inst("tree_plant", far, Vector3(70 + i * 4.0, 0.05, -50), float(i * 25))

	# --- Lighting / atmosphere (editable) ---
	var art := district("14_ArtDirection")
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.68, 0.82)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.82, 0.9)
	e.ambient_light_energy = 0.48
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.62, 0.72, 0.82)
	e.fog_density = 0.0018
	e.fog_aerial_perspective = 0.35
	e.glow_enabled = false
	e.ssao_enabled = false
	env.environment = e
	art.add_child(env)
	env.owner = _city
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_energy = 0.95
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 280.0
	art.add_child(sun)
	sun.owner = _city
	var fill := OmniLight3D.new()
	fill.name = "CrystalFill"
	fill.position = Vector3(0, 7, 0)
	fill.light_color = Color(0.4, 0.65, 1.0)
	fill.light_energy = 1.1
	fill.omni_range = 24.0
	art.add_child(fill)
	fill.owner = _city
	var gate_fill := OmniLight3D.new()
	gate_fill.name = "GateFill"
	gate_fill.position = Vector3(0, 6, -78)
	gate_fill.light_color = Color(1.0, 0.85, 0.55)
	gate_fill.light_energy = 0.9
	gate_fill.omni_range = 22.0
	art.add_child(gate_fill)
	gate_fill.owner = _city

	# Spawn marker
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0, 0.5, -60)
	_city.add_child(spawn)
	spawn.owner = _city

	DirAccess.make_dir_recursive_absolute("/home/gamedev/LunexMMOKit/client/world/locations/eternity_capital")
	var packed := PackedScene.new()
	packed.pack(_city)
	var err := ResourceSaver.save(packed, OUT)
	print("CAPITAL_SAVE ", err, " children ", _city.get_child_count())
	_city.free()
	quit(0 if err == OK else 1)
