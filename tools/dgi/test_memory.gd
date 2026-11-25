extends SceneTree
func _initialize(): call_deferred("run")
func sample(label: String):
	print("MEM ",label," static=",OS.get_static_memory_usage()," objects=",Performance.get_monitor(Performance.OBJECT_COUNT)," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," orphan=",Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
func run():
	var scene = load("res://scenes/training/training.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	sample("initial")
	for i in range(100):
		scene._load_actor(i%4)
		await process_frame
		for kind in ["wing","pet","mount"]:
			scene._select_accessory(1+i%2,kind)
			await process_frame
		for kind in ["mount","pet","wing"]:
			scene._select_accessory(0,kind)
		await process_frame
		if i%25==24: sample("switch_"+str(i+1))
	var combat = scene.combat
	var hits := [0]
	combat.hit_confirmed.connect(func(): hits[0]+=1)
	# Accelerated impact stress: real effect instantiation, not 1000 full animation cycles.
	for i in range(1000):
		combat.hit()
		if i%20==19:
			await create_timer(0.05).timeout
		if i%250==249: sample("impact_"+str(i+1))
	await create_timer(2.2).timeout
	sample("settled")
	print("hits=",hits[0])
	scene.queue_free()
	await process_frame
	await process_frame
	sample("closed")
	quit(0 if hits[0]==1000 else 1)
