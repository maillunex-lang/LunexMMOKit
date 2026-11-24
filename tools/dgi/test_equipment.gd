extends SceneTree
const Equipment = preload("res://equipment.gd")

func _initialize():
	call_deferred("run")

func load_glb(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state)

func expect_transform(actual: Transform3D, expected: Transform3D) -> bool:
	return actual.origin.is_equal_approx(expected.origin) and actual.basis.x.is_equal_approx(expected.basis.x) and actual.basis.y.is_equal_approx(expected.basis.y) and actual.basis.z.is_equal_approx(expected.basis.z)

func run():
	var base := "/home/gamedev/darklord-dgi/exports/"
	var failures := 0
	for pair in [["10001", "100011000"], ["20001", "200011000"], ["30001", "300011000"], ["40001", "400011000"]]:
		var actor := load_glb(base + pair[0] + ".glb")
		var item := load_glb(base + "weapon-" + pair[1] + ".glb")
		if actor == null or item == null:
			failures += 1
			continue
		root.add_child(actor)
		var player: AnimationPlayer = actor.find_children("*", "AnimationPlayer", true, false)[0]
		var handle := Equipment.equip_weapon(actor, item, pair[1])
		var attached := not handle.is_empty()
		var transform_ok := attached
		var right_name := ""
		var left_name := ""
		if attached and String(handle.get("mode")) == "single":
			var marker: Node3D = handle.get("marker")
			transform_ok = item.get_parent() == marker and expect_transform(item.transform, Transform3D.IDENTITY)
			right_name = marker.name if marker else ""
		elif attached:
			for entry in handle.get("attachments", []):
				var node: Node3D = entry.get("node")
				var marker: Node3D = entry.get("marker")
				if String(entry.get("name")) == "body2":
					right_name = marker.name
					transform_ok = transform_ok and node.get_parent() == marker and expect_transform(node.transform, entry.get("spec_transform"))
				elif String(entry.get("name")) == "body1":
					left_name = marker.name
					transform_ok = transform_ok and node.get_parent() == marker and expect_transform(node.transform, entry.get("spec_transform"))
		var moved := false
		var sampled := 0
		if attached:
			var probe: Node3D = item
			if String(handle.get("mode")) == "dual":
				probe = handle["attachments"][0]["node"]
			var initial := probe.global_transform
			for anim in player.get_animation_list():
				var lower := anim.to_lower()
				if not ("attack" in lower or "skill" in lower):
					continue
				player.play(anim)
				player.seek(player.get_animation(anim).length * 0.5, true)
				player.advance(0.0)
				sampled += 1
				moved = moved or not initial.is_equal_approx(probe.global_transform)
				if sampled >= 10:
					break
			player.stop()
		print("TEST ", pair[0], " attached=", attached, " transform_ok=", transform_ok, " right=", right_name, " left=", left_name, " sampled=", sampled, " moved=", moved)
		if not attached or not transform_ok or not moved:
			failures += 1
		if not Equipment.unequip_weapon(handle):
			failures += 1
		actor.free()
		if item and is_instance_valid(item) and item.get_parent() == null:
			item.free()
	quit(failures)
