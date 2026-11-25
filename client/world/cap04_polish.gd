extends Node
## CAP04 runtime polish: effect crystal materials, hide shadow-only meshes.
## Does not rewrite capital_geometry_*.tscn (large generated base).
@export var geometry_root: Node3D
@export var hide_shadow_meshes := true
@export var polish_effect_crystal := true

func _ready() -> void:
	if geometry_root == null:
		geometry_root = get_parent() as Node3D
	if geometry_root == null:
		return
	if polish_effect_crystal:
		_polish_effect_crystals()
	if hide_shadow_meshes:
		_hide_shadows()

func _effect_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.75, 1.0, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.25, 0.55, 1.0)
	m.emission_energy_multiplier = 2.2
	m.roughness = 0.18
	m.metallic = 0.15
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _polish_effect_crystals() -> void:
	var mat := _effect_material()
	for n in geometry_root.get_children():
		var asset := String(n.get_meta("source_asset", ""))
		if "cs_zc_03_shuijing" not in asset and "luoxuan" not in asset.to_lower():
			continue
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh == null:
				continue
			for i in range(mi.mesh.get_surface_count()):
				mi.set_surface_override_material(i, mat)
			mi.set_meta("cap04_effect_crystal", true)

func _hide_shadows() -> void:
	for n in geometry_root.get_children():
		var asset := String(n.get_meta("source_asset", ""))
		if "/yinying/" in asset:
			n.visible = false
			n.set_meta("cap04_shadow_hidden", true)
