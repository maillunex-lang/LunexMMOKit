extends SceneTree
const Materials = preload("res://darklord_material.gd")

func _initialize():
	call_deferred("run")

func load_glb(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state)

func textured_meshes(node: Node3D) -> int:
	var count := 0
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if not mesh is MeshInstance3D:
			continue
		var material: Material = mesh.material_override
		if material is ShaderMaterial:
			var texture: Variant = material.get_shader_parameter("main_tex")
			if texture is Texture2D and texture.get_image() != null and texture.get_image().get_width() > 0:
				count += 1
	return count

func run():
	var base := "/home/gamedev/darklord-dgi/"
	var params: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "material-params.json"))
	var pairs := {
		"10001": "100011000",
		"20001": "200011000",
		"30001": "300011000",
		"40001": "400011000",
	}
	var total := 0
	var failures := 0
	for actor_id in pairs:
		var weapon_id: String = pairs[actor_id]
		var actor := load_glb(base + "exports/" + actor_id + ".glb")
		var weapon := load_glb(base + "exports/weapon-" + weapon_id + ".glb")
		if actor == null or weapon == null:
			failures += 1
			continue
		var body_applied := Materials.apply(actor, params[actor_id][0], "/home/gamedev/Darklord")
		var weapon_applied := Materials.apply(weapon, params[weapon_id][0], "/home/gamedev/Darklord")
		var body_textured := textured_meshes(actor)
		var weapon_textured := textured_meshes(weapon)
		var ok := body_applied > 0 and weapon_applied > 0 and body_applied == body_textured and weapon_applied == weapon_textured
		print("MATERIAL ", actor_id, " body=", body_textured, "/", body_applied, " weapon=", weapon_textured, "/", weapon_applied, " ok=", ok)
		if not ok:
			failures += 1
		total += body_textured + weapon_textured
		actor.free()
		weapon.free()
	print("material_total=", total, " failures=", failures)
	quit(0 if failures == 0 and total == 9 else 1)
