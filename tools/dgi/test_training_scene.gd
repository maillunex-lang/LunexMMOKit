extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var packed: PackedScene = load("res://scenes/training/training.tscn")
	if packed == null:
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var failures := 0
	if scene.get_node_or_null("TrainingCamera") == null:
		print("missing camera")
		failures += 1
	if scene.get_node_or_null("TrainingUI/Controls") == null:
		print("missing controls")
		failures += 1
	if scene.get("actor") == null or scene.get("animation_player") == null:
		print("actor_not_ready")
		failures += 1
	if (scene.get("equipment_handle") as Dictionary).is_empty():
		print("weapon_not_equipped")
		failures += 1
	var combat: Variant = scene.get("combat")
	if combat == null or combat.get("projectile_visual") == null or combat.get("impact_visual") == null:
		print("vfx_not_ready")
		failures += 1
	if scene.get("target") == null:
		print("target_missing")
		failures += 1
	var actor_ids: Array = scene.get("actor_ids")
	var index: int = int(scene.get("current_actor_index"))
	print("training_ready=", failures == 0, " actor=", actor_ids[index], " vfx=", combat != null and combat.get("projectile_visual") != null and combat.get("impact_visual") != null)
	if failures > 0:
		quit(2)
		return
	for i in range(4):
		scene.call("_load_actor",i)
		await process_frame
		if scene.get("animation_player")==null or scene.get("equipment_handle").is_empty():
			quit(4)
			return
		if combat.get("attack_audio")==null or combat.get("impact_visual")==null or (i!=2 and scene.get("melee_visual")==null):
			print("missing class assets ",i)
			quit(5)
			return
		scene.call("launch_attack")
		await create_timer(1.5).timeout
		var hp: int = int(combat.get("hp"))
		print("class=",i," hp=",hp)
		if hp != 90:
			quit(3)
			return
	scene.queue_free()
	await process_frame
	await process_frame
	quit(0)
