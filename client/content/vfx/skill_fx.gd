extends Node
## Lightweight skill/hit FX for slice. Uses Darklord pfx path only as provenance tag;
## full Unity particle parity is later. Shows readable feedback now.

func spawn_hit(at: Vector3, color: Color = Color(1.0, 0.7, 0.2), scale := 1.0) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35 * scale
	sphere.height = 0.7 * scale
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.set_surface_override_material(0, mat)
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(mi)
	mi.global_position = at + Vector3(0, 1.0, 0)
	var tw := host.create_tween()
	tw.tween_property(mi, "scale", Vector3(2.2, 2.2, 2.2), 0.25)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(mi.queue_free)

func spawn_cast(at: Vector3, color: Color = Color(0.4, 0.7, 1.0)) -> void:
	spawn_hit(at + Vector3(0, 0.2, 0), color, 0.7)

func color_for_actor(actor_id: String) -> Color:
	match actor_id:
		"30001":
			return Color(0.45, 0.65, 1.0) # mage
		"20001":
			return Color(0.45, 0.9, 0.45) # archer
		"10001":
			return Color(1.0, 0.55, 0.25) # warrior
		"40001":
			return Color(0.85, 0.35, 0.55) # assassin
		_:
			return Color(1.0, 0.85, 0.3)
