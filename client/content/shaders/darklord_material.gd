extends RefCounted
const SHADER = preload("darklord_character.gdshader")
static func texture_from(record: Dictionary, key: String, source_root: String) -> Texture2D:
	var paths: Array = record.get("textures", {}).get(key, {}).get("paths", [])
	if paths.size() != 1:
		return null
	var rel := String(paths[0])
	var full := ""
	# Prefer portable resolver when autoload present (FIX-002).
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/LunexAssets"):
		full = Engine.get_main_loop().root.get_node("/root/LunexAssets").resolve_source_texture(rel)
	if full.is_empty() and source_root != "":
		full = source_root.path_join(rel)
	if full.is_empty() or not FileAccess.file_exists(full):
		return null
	var img := Image.load_from_file(full)
	if img == null or img.is_empty():
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
static func apply(node: Node3D, record: Dictionary, source_root: String) -> int:
	var main := texture_from(record, "_MainTex", source_root)
	if main == null:
		return 0
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("main_tex", main)
	var params: Dictionary = record.get("params", {})
	for pair in [["_SpecPower","spec_power"],["_SpecPower2","spec_power2"],["_SpecIntensity","spec_intensity"],["_SpecIntensity2","spec_intensity2"],["_Cutout","cutoff"]]:
		mat.set_shader_parameter(pair[1], params.get(pair[0], 1.0))
	mat.set_shader_parameter("cutout", params.get("_EnableCutout", 0.0) != 0.0)
	var spec := texture_from(record, "_SpecTex", source_root)
	if spec != null: mat.set_shader_parameter("spec_tex", spec)
	var flow := texture_from(record, "_FlowTex", source_root)
	var mask := texture_from(record, "_FlowMaskTex", source_root)
	if flow != null and mask != null and params.get("_EnableFlow", 0.0) != 0.0:
		mat.set_shader_parameter("flow_enabled", true)
		mat.set_shader_parameter("flow_tex", flow)
		mat.set_shader_parameter("flow_mask", mask)
		var speed: Array = params.get("_FlowAni", [0.0,0.0])
		var scale: Array = params.get("_FlowScale", [1.0,1.0])
		var offset: Array = params.get("_FlowOffset", [0.0,0.0])
		var color: Array = params.get("_FlowColor", [1.0,1.0,1.0])
		mat.set_shader_parameter("flow_speed", Vector2(speed[0],speed[1]))
		mat.set_shader_parameter("flow_scale", Vector2(scale[0],scale[1]))
		mat.set_shader_parameter("flow_offset", Vector2(offset[0],offset[1]))
		mat.set_shader_parameter("flow_color", Color(color[0],color[1],color[2]))
		mat.set_shader_parameter("flow_intensity", params.get("_FlowIntensity",1.0))
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	for mesh in meshes:
		mesh.material_override = mat
	return meshes.size()
