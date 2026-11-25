extends SceneTree
func _initialize() -> void:
	call_deferred("go")
func go() -> void:
	var scene: Node3D = load("res://scenes/training/training.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	for i in range(4):
		scene._load_actor(i)
		await process_frame
		var a: Node3D = scene.actor
		var ap: AnimationPlayer = scene.animation_player
		print("CLASS ",i," mounted duration=",ap.get_animation("mount_stand").length)
		for clip in ["stand","mount_stand"]:
			ap.play(clip)
			ap.seek(ap.get_animation(clip).length*0.4,true)
			ap.advance(0)
			print("CLIP ",clip)
			for part in ["Bip001 L Thigh","Bip001 L Calf","Bip001 R Thigh","Bip001 R Calf"]:
				var bone=a.find_child(part,true,false)
				if bone!=null:
					print(part," rotation=",bone.rotation," quat=",bone.quaternion," path=",a.get_path_to(bone))
		print("PRE_SELECTED ",scene.animation_select.item_count," mount_idx=",scene.animation_select.get_item_text(scene.animation_select.item_count-2)," player=",ap.current_animation)
		scene._select_accessory(1,"mount")
		print("POST_CALL ",ap.current_animation," selected=",scene.animation_select.selected," text=",scene.animation_select.get_item_text(scene.animation_select.selected))
		await process_frame
		print("AFTER SELECT playing=",ap.current_animation," pos=",ap.current_animation_position," parent=",a.get_parent().name)
		ap.advance(0.1)
		print("AFTER ADVANCE playing=",ap.current_animation)
		assert(ap.current_animation == "mount_stand")
		scene._select_accessory(0,"mount")
	scene.queue_free()
	await process_frame
	quit()
