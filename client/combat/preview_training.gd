extends Node3D
const Projectile = preload("preview_projectile.gd")
signal hit_confirmed
var target: Node3D
var origin: Node3D
var hp := 100
func launch():
	if not is_instance_valid(target) or not is_instance_valid(origin): return
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
	p.add_child(visual)
	p.arrived.connect(hit)
func hit():
	if not is_instance_valid(target): return
	hp = maxi(0,hp-10)
	target.rotation.z = 0.2
	hit_confirmed.emit()
