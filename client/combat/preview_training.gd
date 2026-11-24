extends Node3D
const Projectile = preload("preview_projectile.gd")
signal hit_confirmed
var target: Node3D
var origin: Node3D
var hp := 100
var attack_audio: AudioStream
var projectile_visual: PackedScene
var impact_visual: PackedScene
func play_attack_sound():
	if attack_audio == null: return
	var audio := AudioStreamPlayer3D.new()
	add_child(audio)
	audio.global_position = origin.global_position
	audio.stream = attack_audio
	audio.finished.connect(audio.queue_free)
	audio.play()
func launch():
	if not is_instance_valid(target) or not is_instance_valid(origin): return
	play_attack_sound()
	var p := Projectile.new()
	add_child(p)
	p.global_position = origin.global_position
	p.target = target
	var visual := MeshInstance3D.new()
	visual.mesh = SphereMesh.new()
	visual.scale = Vector3.ONE * 0.15
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.ORANGE
	visual.material_override = mat
	if projectile_visual != null:
		visual.free()
		p.add_child(projectile_visual.instantiate())
	else:
		p.add_child(visual)
	p.arrived.connect(hit)
func hit():
	if not is_instance_valid(target): return
	hp = maxi(0,hp-10)
	target.rotation.z = 0.2
	if impact_visual != null:
		var fx := impact_visual.instantiate() as Node3D
		add_child(fx)
		fx.global_position = target.global_position
		get_tree().create_timer(2.0).timeout.connect(fx.queue_free)
	hit_confirmed.emit()
