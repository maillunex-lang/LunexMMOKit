extends SceneTree
## Chapter-1 third location: Shard Ruins. FIX-004: writes *_generated.tscn by default.
const KIT := "res://world/library/kits/"
const OUT_GENERATED := "res://world/locations/shard_ruins/shard_ruins_generated.tscn"
const OUT_OWNER := "res://world/locations/shard_ruins/shard_ruins.tscn"
const OUT := OUT_GENERATED
const OwnerProtect = preload("res://world/owner_protect.gd")

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
	var force := "--force-overwrite" in OS.get_cmdline_user_args() or "--force-overwrite" in OS.get_cmdline_args()
	if "--write-owner" in OS.get_cmdline_user_args() or "--write-owner" in OS.get_cmdline_args():
		var gate: Dictionary = OwnerProtect.refuse_overwrite(OUT_OWNER, force)
		if not bool(gate.get("ok", false)):
			print("OWNER_PROTECT refuse ", gate.get("reason", "?"))
			quit(2)
			return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://world/locations/shard_ruins"))
	_root = Node3D.new()
	_root.name = "ShardRuins"
	_root.set_meta("location_id", "shard_ruins")
	_root.set_meta("location_revision", 1)
	_root.set_meta("generated", true)
	root.add_child(_root)

	for x in range(-2, 3):
		for z in range(-2, 3):
			inst("ground_tile", _root, Vector3(x * 20.0, 0.0, z * 20.0))

	# Broken ring of stones + crystal heart
	for i in range(8):
		var ang := i * TAU / 8.0
		inst(["rock_01", "rock_02"][i % 2], _root, Vector3(cos(ang) * 12.0, 0.05, sin(ang) * 12.0), rad_to_deg(ang), Vector3(1.4, 1.1, 1.4))
	inst("crystal_01", _root, Vector3(0, 0.05, 0), 0.0, Vector3(0.9, 1.3, 0.9))
	inst("statue_base", _root, Vector3(0, 0.05, 0), 0.0, Vector3(0.7, 0.5, 0.7))
	inst("arch_jz01", _root, Vector3(0, 0.05, -18), 0.0, Vector3(0.75, 0.75, 0.75))
	inst("tree_plant", _root, Vector3(-10, 0.05, -8), 25.0)
	inst("bush_01", _root, Vector3(8, 0.05, 6))
	inst("lamp_01", _root, Vector3(-4, 0.05, -14))

	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.set_meta("stable_id", "spawn_ruins")
	_root.add_child(spawn)
	spawn.position = Vector3(0, 1.0, -14)
	spawn.owner = _root

	var portal := Node3D.new()
	portal.name = "Portal_BackAshen"
	portal.set_meta("stable_id", "portal_ruins_exit")
	portal.set_meta("portal_id", "ruins_exit")
	portal.set_meta("target_location", "ashen_outskirts")
	portal.set_meta("target_scene", "res://world/locations/ashen_outskirts/ashen_play.tscn")
	_root.add_child(portal)
	portal.position = Vector3(0, 0.05, -18)
	portal.owner = _root

	var scholar := Node3D.new()
	scholar.name = "ShardScholar"
	scholar.set_meta("stable_id", "npc_shard_scholar")
	scholar.set_meta("npc_role", "quest")
	_root.add_child(scholar)
	scholar.position = Vector3(3, 0.05, -6)
	scholar.owner = _root
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.5
	body.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.5, 0.75)
	body.set_surface_override_material(0, mat)
	body.position.y = 0.9
	scholar.add_child(body)
	body.owner = _root

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.25, 0.28, 0.45)
	sm.sky_horizon_color = Color(0.55, 0.4, 0.55)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.3
	env.environment = e
	_root.add_child(env)
	env.owner = _root
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -20, 0)
	sun.light_energy = 0.85
	_root.add_child(sun)
	sun.owner = _root

	var packed := PackedScene.new()
	packed.pack(_root)
	var err := ResourceSaver.save(packed, OUT_GENERATED)
	print("RUINS_SAVE ", err, " ", OUT_GENERATED)
	quit(0 if err == OK else 1)
