extends SceneTree
const Attack = preload("res://preview_attack.gd")
const Training = preload("res://preview_training.gd")
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
	print("socket=",marker.name," audio_seconds=",audio.get_length())
	training.origin = marker
	var target := MeshInstance3D.new()
	target.mesh = CapsuleMesh.new()
	training.add_child(target)
	target.global_position = marker.global_position + Vector3(1.2,0,0)
	training.target = target
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
	await create_timer(0.65).timeout
	var ok: bool = before==100 and training.hp==90 and events==["launch","hit"]
	print("before=",before," after=",training.hp," events=",events," ok=",ok)
	quit(0 if ok else 1)
