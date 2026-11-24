extends SceneTree
const Equipment = preload("res://equipment.gd")
func _initialize():
	call_deferred("run")
func load_glb(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path,state) != OK:
		return null
	return doc.generate_scene(state)
func run():
	var base := "/home/gamedev/darklord-dgi/exports/"
	var failures := 0
	for pair in [["10001","100011000"],["20001","200011000"],["30001","300011000"],["40001","400011000"]]:
		var actor := load_glb(base+pair[0]+".glb")
		var item := load_glb(base+"weapon-"+pair[1]+".glb")
		if actor == null or item == null:
			failures += 1
			continue
		root.add_child(actor)
		var sk := actor.find_children("*","Skeleton3D",true,false)
		var ap := actor.find_children("*","AnimationPlayer",true,false)
		if sk.size()!=1 or ap.is_empty():
			failures += 1
			actor.free()
			item.free()
			continue
		var skeleton: Skeleton3D = sk[0]
		var player: AnimationPlayer = ap[0]
		var names := []
		for i in skeleton.get_bone_count():
			if "Hand" in skeleton.get_bone_name(i) or "Prop" in skeleton.get_bone_name(i):
				names.append(skeleton.get_bone_name(i))

		var socket := Equipment.attach_marker(actor,"DM_R_Hand2",item)
		var left_marker: Node3D = null
		if pair[0] == "40001" and socket:
			var right := item.find_child("body2",true,false) as Node3D
			var left := item.find_child("body1",true,false) as Node3D
			if right == null or left == null:
				failures += 1
			else:
				right.reparent(socket,false)
				left.get_parent().remove_child(left)
				left_marker = Equipment.attach_marker(actor,"DM_L_Hand2",left)
				if left_marker == null:
					failures += 1
					left.free()
		var clips := 0
		var moved := false
		var initial := item.global_transform if socket else Transform3D.IDENTITY
		if socket:
			for anim in player.get_animation_list():
				if "attack" in anim or "skill" in anim:
					player.play(anim)
					player.seek(player.get_animation(anim).length*0.5,true)
					player.advance(0)
					clips += 1
					moved = moved or not initial.is_equal_approx(item.global_transform)
		else:
			failures += 1
			item.free()
		print("TEST ",pair[0]," bones=",names," attached=",socket!=null," sampled=",clips," moved=",moved," left=",left_marker!=null)
		if not moved: failures += 1
		actor.free()
	quit(failures)
