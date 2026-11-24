extends SceneTree
const VFX = preload("res://particle_preview.gd")
const Attack = preload("res://preview_attack.gd")
const Training = preload("res://preview_training.gd")
func own_tree(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		own_tree(child, owner)

func _initialize():
	call_deferred("run")
func run():
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file("/home/gamedev/darklord-dgi/exports/30001.glb",state)!=OK:
		quit(1)
		return
	var actor := doc.generate_scene(state)
	root.add_child(actor)
	var player := actor.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	var training := Training.new()
	root.add_child(training)
	var marker := actor.find_child("E_fire",true,false) as Node3D
	if marker == null:
		quit(3)
		return
	var audio := AudioStreamMP3.load_from_file("/home/gamedev/Darklord/Client/Assets/Resources/Sound/skill/FS_Atk_01.mp3")
	if audio == null or audio.get_length() <= 0:
		quit(4)
		return
	training.attack_audio = audio
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("/home/gamedev/darklord-dgi/particle-index.json"))
	for key in records:
		var fx := VFX.build(records[key],"/home/gamedev/Darklord")
		own_tree(fx, fx)
		var packed := PackedScene.new()
		if packed.pack(fx)!=OK:
			quit(5)
			return
		if key.ends_with("FS_hti.prefab"): training.impact_visual = packed
		else: training.projectile_visual = packed
		print("VFX ",key," emitters=",Preview.emitter_count(fx))
		fx.free()
	print("socket=",marker.name," audio_seconds=",audio.get_length())
	training.origin = marker
	var target := MeshInstance3D.new()
	target.mesh = CapsuleMesh.new()
	training.add_child(target)
	target.global_position = marker.global_position + Vector3(1.2,0,0)
	training.target = target
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(3,2.5,5)
	camera.look_at(Vector3(0.6,1,0))
	camera.current = true
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-45,-30,0)
	var attack := Attack.new()
	root.add_child(attack)
	attack.projectile.connect(training.launch)
	var events := []
	attack.projectile.connect(func(): events.append("launch"))
	training.hit_confirmed.connect(func(): events.append("hit"))
	if not attack.begin(player,"attack001",[{"kind":"projectile","time":0.5}]):
		quit(2)
		return
	await create_timer(0.7).timeout
	var before := training.hp
	await RenderingServer.frame_post_draw
	print("flight capture=",root.get_texture().get_image().save_png("/home/gamedev/darklord-dgi/screens/combat-flight.png"))
	await create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	print("impact capture=",root.get_texture().get_image().save_png("/home/gamedev/darklord-dgi/screens/combat-impact.png"))
	var ok: bool = before==100 and training.hp==90 and events==["launch","hit"]
	print("before=",before," after=",training.hp," events=",events," ok=",ok)
	quit(0 if ok else 1)
