extends SceneTree
const Attack = preload("res://preview_attack.gd")
func _initialize():
	call_deferred("run")
func run():
	var failures := 0
	for row in [["10001","hit",0.15],["20001","hit",0.3],["30001","projectile",0.5],["40001","hit",0.4]]:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file("/home/gamedev/darklord-dgi/exports/"+row[0]+".glb",state)!=OK:
			failures+=1
			continue
		var actor := doc.generate_scene(state)
		root.add_child(actor)
		var player := actor.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
		var target := MeshInstance3D.new()
		target.mesh = CapsuleMesh.new()
		target.position = Vector3(0,0.8,2)
		root.add_child(target)
		target.set_meta("hp",100)
		var attack := Attack.new()
		root.add_child(attack)
		var stamps := []
		attack.impact.connect(func():
			target.set_meta("hp",target.get_meta("hp")-10)
			target.rotation.z=0.2
			stamps.append(player.current_animation_position))
		attack.projectile.connect(func(): stamps.append(player.current_animation_position))
		if not attack.begin(player,"attack001",[{"kind":row[1],"time":row[2]}]):
			failures+=1
		await create_timer(1.5).timeout
		var ok: bool = stamps.size()==1 and target.get_meta("hp")== (90 if row[1]=="hit" else 100)
		if ok: ok=absf(stamps[0]-row[2])<0.08
		if not ok: failures+=1
		print(row[0]," event=",stamps," hp=",target.get_meta("hp")," ok=",ok)
		attack.free()
		target.free()
		actor.free()
	print("FAILURES=",failures)
	quit(failures)
