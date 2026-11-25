extends SceneTree
## Chapter-1 second location: Ashen Outskirts (Пепельный рубеж). Own layout; Darklord kits only.
const KIT := "res://world/library/kits/"
const OUT := "res://world/locations/ashen_outskirts/ashen_outskirts.tscn"

var _root: Node3D

func _initialize():
	call_deferred("run")

func inst(id: String, parent: Node3D, pos: Vector3, yaw: float = 0.0, scale := Vector3.ONE) -> Node3D:
	var path := KIT + id + ".tscn"
	if not ResourceLoader.exists(path):
		print("MISSING ", id)
		return null
	var n: Node3D = load(path).instantiate()
	n.name = id + "_" + str(parent.get_child_count())
	parent.add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw
	n.scale = scale
	_own(n, _root)
	return n

func _own(n: Node, owner: Node) -> void:
	n.owner = owner
	for c in n.get_children():
		_own(c, owner)

func run():
	DirAccess.make_dir_recursive_absolute("/home/gamedev/LunexMMOKit/client/world/locations/ashen_outskirts")
	_root = Node3D.new()
	_root.name = "AshenOutskirts"
	_root.set_meta("location_id", "ashen_outskirts")
	_root.set_meta("location_revision", 1)
	root.add_child(_root)

	for x in range(-3, 4):
		for z in range(-3, 4):
			inst("ground_tile", _root, Vector3(x * 20.0, 0.0, z * 20.0))

	# Ruined approach — own composition
	inst("rock_01", _root, Vector3(-8, 0.05, -6), 20.0, Vector3(1.5, 1.2, 1.5))
	inst("rock_02", _root, Vector3(10, 0.05, 4), -30.0, Vector3(1.8, 1.4, 1.8))
	inst("tree_01", _root, Vector3(-14, 0.05, 8), 40.0)
	inst("tree_plant", _root, Vector3(12, 0.05, -10), -15.0)
	inst("bush_01", _root, Vector3(4, 0.05, 6))
	inst("bush_01", _root, Vector3(-6, 0.05, -12))
	inst("lamp_01", _root, Vector3(0, 0.05, -4))
	inst("arch_jz03", _root, Vector3(0, 0.05, -16), 0.0, Vector3(0.8, 0.8, 0.8))
	inst("crystal_01", _root, Vector3(0, 0.05, -16), 0.0, Vector3(0.4, 0.6, 0.4))

	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.set_meta("stable_id", "spawn_ashen")
	spawn.set_meta("respawn_id", "ashen_default")
	_root.add_child(spawn)
	spawn.position = Vector3(0, 1.0, -8)
	spawn.owner = _root

	var portal := Node3D.new()
	portal.name = "Portal_BackToCapital"
	portal.set_meta("stable_id", "portal_capital_return")
	portal.set_meta("portal_id", "capital_return")
	portal.set_meta("target_location", "eternity_capital")
	portal.set_meta("target_scene", "res://world/locations/eternity_capital/eternity_play.tscn")
	_root.add_child(portal)
	portal.position = Vector3(0, 0.05, -16)
	portal.owner = _root
	inst("crystal_01", portal, Vector3(0, 0, 0), 0.0, Vector3(0.3, 0.5, 0.3))

	# Forward portal → Shard Ruins
	var ruins := Node3D.new()
	ruins.name = "Portal_RuinsGate"
	ruins.set_meta("stable_id", "portal_ruins_gate")
	ruins.set_meta("portal_id", "ruins_gate")
	ruins.set_meta("target_location", "shard_ruins")
	ruins.set_meta("target_scene", "res://world/locations/shard_ruins/ruins_play.tscn")
	_root.add_child(ruins)
	ruins.position = Vector3(10, 0.05, 8)
	ruins.owner = _root
	inst("arch_jz02", _root, Vector3(10, 0.05, 8), 90.0, Vector3(0.65, 0.65, 0.65))
	inst("crystal_01", ruins, Vector3(0, 0, 0), 0.0, Vector3(0.35, 0.55, 0.35))

	var warden := Node3D.new()
	warden.name = "AshenWarden"
	warden.set_meta("stable_id", "npc_ashen_warden")
	warden.set_meta("npc_role", "quest")
	_root.add_child(warden)
	warden.position = Vector3(3, 0.05, -10)
	warden.owner = _root
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.5
	body.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.45, 0.35)
	body.set_surface_override_material(0, mat)
	body.position.y = 0.9
	warden.add_child(body)
	body.owner = _root

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.45, 0.35, 0.4)
	sm.sky_horizon_color = Color(0.7, 0.55, 0.45)
	sm.ground_horizon_color = Color(0.35, 0.28, 0.25)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.32
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_root.add_child(env)
	env.owner = _root
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 0.95
	_root.add_child(sun)
	sun.owner = _root

	var packed := PackedScene.new()
	packed.pack(_root)
	var err := ResourceSaver.save(packed, OUT)
	print("ASHEN_SAVE ", err, " ", OUT)
	quit(0 if err == OK else 1)
