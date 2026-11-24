extends SceneTree

const EXPORT_DIR := "/home/gamedev/darklord-dgi/exports"
const OUT_JSON := "/home/gamedev/darklord-dgi/kimi-audit.json"
const ACTORS := {
	"10001": {"label": "warrior", "profession": 3, "weapon": "100011000"},
	"20001": {"label": "archer", "profession": 2, "weapon": "200011000"},
	"30001": {"label": "mage", "profession": 1, "weapon": "300011000"},
	"40001": {"label": "assassin", "profession": 4, "weapon": "400011000"},
}
const MARKERS := ["DM_R_Hand", "DM_L_Hand", "DM_R_Hand2", "DM_L_Hand2", "DM_R_wuqi01", "DM_L_wuqi01", "E_fire", "E_back", "E_back2", "Horse_E_back"]

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.000001), snappedf(v.y, 0.000001), snappedf(v.z, 0.000001)]

func q(qv: Quaternion) -> Array:
	return [snappedf(qv.x, 0.000001), snappedf(qv.y, 0.000001), snappedf(qv.z, 0.000001), snappedf(qv.w, 0.000001)]

func basis_info(b: Basis) -> Dictionary:
	return {
		"determinant": snappedf(b.determinant(), 0.000001),
		"x": v3(b.x), "y": v3(b.y), "z": v3(b.z),
		"negative_scale": b.determinant() < 0.0,
	}

func transform_info(t: Transform3D) -> Dictionary:
	return {"origin": v3(t.origin), "basis": basis_info(t.basis), "quaternion": q(t.basis.get_rotation_quaternion())}

func load_glb(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	var scene := doc.generate_scene(state)
	return scene as Node3D

func node_brief(n: Node, depth: int, out: Array, negative_scales: Array) -> void:
	if out.size() >= 500:
		return
	if n is Node3D:
		var nd: Node3D = n
		var rec := {
			"name": n.name,
			"type": n.get_class(),
			"depth": depth,
			"position": v3(nd.position),
			"rotation_degrees": v3(nd.rotation_degrees),
			"scale": v3(nd.scale),
			"determinant": snappedf(nd.basis.determinant(), 0.000001),
		}
		if MARKERS.has(str(n.name)):
			rec["marker"] = true
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			rec["surface_count"] = mi.mesh.get_surface_count() if mi.mesh else 0
			rec["skin"] = mi.skin != null
			rec["skeleton_path"] = str(mi.skeleton)
		if n is AnimationPlayer:
			var ap := n as AnimationPlayer
			rec["animation_count"] = ap.get_animation_list().size()
		out.append(rec)
		if nd.basis.determinant() < 0.0:
			negative_scales.append({"name": n.get_path(), "determinant": snappedf(nd.basis.determinant(), 0.000001), "scale": v3(nd.scale)})
	for c in n.get_children():
		node_brief(c, depth + 1, out, negative_scales)

func inspect_material(mat: Material) -> Dictionary:
	var rec := {"name": mat.resource_name, "class": mat.get_class()}
	if mat is StandardMaterial3D:
		var sm := mat as StandardMaterial3D
		rec["shading_mode"] = sm.shading_mode
		rec["albedo_color"] = [sm.albedo_color.r, sm.albedo_color.g, sm.albedo_color.b, sm.albedo_color.a]
		rec["transparency"] = sm.transparency
		rec["blend_mode"] = sm.blend_mode
		rec["cull_mode"] = sm.cull_mode
		if sm.albedo_texture:
			var tex_path := str(sm.albedo_texture.resource_path)
			rec["albedo_texture"] = tex_path if tex_path != "" else "<embedded>"
			var img := sm.albedo_texture.get_image()
			if img:
				rec["albedo_texture_size"] = [img.get_width(), img.get_height()]
		else:
			rec["albedo_texture"] = ""
		rec["metallic"] = sm.metallic
		rec["roughness"] = sm.roughness
		rec["emission_enabled"] = sm.emission_enabled
		if sm.emission_enabled:
			rec["emission"] = [sm.emission.r, sm.emission.g, sm.emission.b, sm.emission.a]
	if mat is ShaderMaterial:
		var hm := mat as ShaderMaterial
		rec["shader"] = hm.shader.resource_path if hm.shader else ""
	return rec

func inspect_mesh_materials(actor: Node3D) -> Array:
	var mats := []
	var seen := {}
	for mi in actor.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			var mat := mesh.get_active_material(surface)
			if mat == null:
				continue
			var key := str(mat.get_instance_id()) + ":" + str(surface)
			if seen.has(key):
				continue
			seen[key] = true
			var rec := inspect_material(mat)
			rec["mesh"] = mesh.name
			rec["surface"] = surface
			mats.append(rec)
	return mats

func inspect_skeleton(actor: Node3D) -> Array:
	var result := []
	for sk in actor.find_children("*", "Skeleton3D", true, false):
		var s := sk as Skeleton3D
		var bones := []
		for i in range(s.get_bone_count()):
			var name := s.get_bone_name(i)
			if name.find("Hand") >= 0 or name.find("wuqi") >= 0 or name.find("Prop") >= 0 or name.find("Root") >= 0 or name.find("Spine") >= 0:
				bones.append({"index": i, "name": name, "parent": s.get_bone_parent(i), "rest_origin": v3(s.get_bone_rest(i).origin)})
		result.append({"node": s.name, "bone_count": s.get_bone_count(), "selected_bones": bones})
	return result

func inspect_markers(actor: Node3D) -> Dictionary:
	var result := {}
	for marker in MARKERS:
		var found := actor.find_children(marker, "Node3D", true, false)
		if found.size() > 0:
			var nodes := []
			for n in found:
				var nd := n as Node3D
				nodes.append({"name": nd.name, "path": str(nd.get_path()), "transform": transform_info(nd.transform)})
			result[marker] = nodes
	return result

func inspect_animations(actor: Node3D) -> Array:
	var result := []
	for ap in actor.find_children("*", "AnimationPlayer", true, false):
		var player := ap as AnimationPlayer
		var animations := []
		var category := {"idle": 0, "walk": 0, "run": 0, "attack": 0, "skill": 0, "hit": 0, "death": 0, "dodge": 0, "victory": 0, "other": 0}
		for anim_name in player.get_animation_list():
			var anim := player.get_animation(anim_name)
			var tracks := {"total": anim.get_track_count(), "missing_targets": 0, "types": {}}
			var root := player.get_node_or_null(player.root_node)
			for t in range(anim.get_track_count()):
				var typ := anim.track_get_type(t)
				tracks["types"][str(typ)] = int(tracks["types"].get(str(typ), 0)) + 1
				if root and root.get_node_or_null(anim.track_get_path(t)) == null:
					tracks["missing_targets"] += 1
			var lower := anim_name.to_lower()
			var cat := "other"
			for key in ["idle", "walk", "run", "attack", "skill", "hit", "death", "die", "dodge", "victory"]:
				if lower.find(key) >= 0:
					cat = "death" if key == "die" else key
					break
			category[cat] = int(category.get(cat, 0)) + 1
			animations.append({"name": anim_name, "length": snappedf(anim.length, 0.000001), "loop_mode": anim.loop_mode, "tracks": tracks, "category": cat})
		result.append({"node": player.name, "animation_count": animations.size(), "categories": category, "animations": animations})
	return result

func aabb_info(actor: Node3D) -> Dictionary:
	var first := true
	var bounds := AABB(Vector3.ZERO, Vector3.ZERO)
	for mi in actor.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi as MeshInstance3D
		if mesh.mesh == null:
			continue
		var local := mesh.get_aabb()
		var points := [local.position, local.position + local.size, Vector3(local.position.x + local.size.x, local.position.y, local.position.z), Vector3(local.position.x, local.position.y + local.size.y, local.position.z), Vector3(local.position.x, local.position.y, local.position.z + local.size.z), Vector3(local.position.x + local.size.x, local.position.y + local.size.y, local.position.z), Vector3(local.position.x + local.size.x, local.position.y, local.position.z + local.size.z), Vector3(local.position.x, local.position.y + local.size.y, local.position.z + local.size.z)]
		for p in points:
			var g: Vector3 = (mesh.global_transform if mesh.is_inside_tree() else mesh.transform) * p
			if first:
				bounds = AABB(g, Vector3.ZERO)
				first = false
			else:
				bounds = bounds.expand(g)
	return {"min": v3(bounds.position), "max": v3(bounds.position + bounds.size), "size": v3(bounds.size), "has_geometry": not first}

func attach_sample(actor: Node3D, item: Node3D) -> Dictionary:
	var player_nodes := actor.find_children("*", "AnimationPlayer", true, false)
	if player_nodes.is_empty():
		return {"supported": false, "reason": "no AnimationPlayer"}
	var player := player_nodes[0] as AnimationPlayer
	var marker := actor.find_child("DM_R_Hand2", true, false) as Node3D
	if marker == null:
		marker = actor.find_child("DM_R_Hand", true, false) as Node3D
	if marker == null:
		return {"supported": false, "reason": "no right hand marker"}
	marker.add_child(item)
	var initial := item.global_transform
	var sampled := []
	for anim_name in player.get_animation_list():
		var lower := anim_name.to_lower()
		if not ("attack" in lower or "skill" in lower):
			continue
		player.play(anim_name)
		player.seek(player.get_animation(anim_name).length * 0.5, true)
		player.advance(0.0)
		var moved := not initial.is_equal_approx(item.global_transform)
		sampled.append({"animation": anim_name, "moved": moved, "weapon_origin": v3(item.global_transform.origin)})
		if sampled.size() >= 12:
			break
	player.stop()
	return {"supported": true, "marker": marker.name, "sampled": sampled, "all_moved": sampled.all(func(s): return s["moved"])}

func inspect_one(actor_id: String, info: Dictionary) -> Dictionary:
	var actor_path := EXPORT_DIR.path_join(actor_id + ".glb")
	var weapon_path := EXPORT_DIR.path_join("weapon-" + info.weapon + ".glb")
	var actor := load_glb(actor_path)
	var item := load_glb(weapon_path)
	if actor == null or item == null:
		failures += 1
		return {"id": actor_id, "error": "load failed", "actor_path": actor_path, "weapon_path": weapon_path}
	root.add_child(actor)
	actor.name = info.label
	var nodes := []
	var negative_scales := []
	node_brief(actor, 0, nodes, negative_scales)
	var record := {
		"id": actor_id,
		"label": info.label,
		"profession": info.profession,
		"weapon_id": info.weapon,
		"actor_path": actor_path,
		"weapon_path": weapon_path,
		"actor_nodes": nodes,
		"negative_scale_nodes": negative_scales,
		"bounds": aabb_info(actor),
		"skeletons": inspect_skeleton(actor),
		"markers": inspect_markers(actor),
		"animation_players": inspect_animations(actor),
		"materials": inspect_mesh_materials(actor),
		"weapon": {
			"id": info.weapon,
			"nodes": [],
			"negative_scale_nodes": [],
			"bounds": {},
			"materials": [],
			"body_children": [],
		},
		"attachment_sample": {},
	}
	var weapon_nodes := []
	var weapon_negative := []
	node_brief(item, 0, weapon_nodes, weapon_negative)
	record.weapon.nodes = weapon_nodes
	record.weapon.negative_scale_nodes = weapon_negative
	record.weapon.bounds = aabb_info(item)
	record.weapon.materials = inspect_mesh_materials(item)
	for child_name in ["body1", "body2"]:
		var child := item.find_child(child_name, true, false) as Node3D
		if child:
			record.weapon.body_children.append({"name": child.name, "transform": transform_info(child.transform), "parent": str(child.get_parent().name)})
	record.attachment_sample = attach_sample(actor, item)
	actor.free()
	if item and is_instance_valid(item) and item.get_parent() == null:
		item.free()
	return record

func run() -> void:
	var results := []
	for actor_id in ACTORS.keys():
		var rec := inspect_one(actor_id, ACTORS[actor_id])
		results.append(rec)
		var anim_count := 0
		for player in rec.get("animation_players", []):
			anim_count += int(player.get("animation_count", 0))
		print("AUDIT ", actor_id, " label=", rec.get("label"), " anims=", anim_count, " markers=", rec.get("markers", {}).keys(), " failures=", failures)
	var payload := {"generated_by": "tools/dgi/kimi_actor_audit.gd", "godot": Engine.get_version_info().get("string", ""), "failures": failures, "actors": results}
	var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "  "))
		f.close()
	else:
		failures += 1
	print("WROTE ", OUT_JSON, " failures=", failures)
	quit(0 if failures == 0 else 1)
