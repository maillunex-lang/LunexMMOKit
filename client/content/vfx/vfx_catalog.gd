extends RefCounted
## D05: resolve used-asset particle prefabs from particle-index + optional overrides.

const ParticlePreview = preload("res://content/vfx/particle_preview.gd")

const CLASS_ATTACK_PREFABS := {
	"10001": "Client/Assets/Resources/Effect/skill/player/ZS_M/ZS_M_attack001.prefab",
	"20001": "Client/Assets/Resources/Effect/skill/player/GJS_M/GJS_M_attack001.prefab",
	"30001": "Client/Assets/Resources/Effect/skill/player/FS_W/FS_W_attack001.prefab",
	"40001": "Client/Assets/Resources/Effect/skill/player/CK_W/CK_W_attack001.prefab",
}
const HURT_PREFAB := "Client/Assets/Resources/Effect/skill/hurt/FS_hti.prefab"

static func load_index(path: String = "") -> Dictionary:
	var p := path
	if p.is_empty():
		var assets: Node = Engine.get_main_loop().root.get_node_or_null("/root/LunexAssets") if Engine.get_main_loop() else null
		if assets and assets.has_method("particle_index_path"):
			p = String(assets.particle_index_path())
		if p.is_empty():
			p = ProjectSettings.globalize_path("res://../assets/studio/particle-index.json")
	if p.is_empty() or not FileAccess.file_exists(p):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return parsed if parsed is Dictionary else {}

static func payload_for(prefab_key: String, index: Dictionary = {}) -> Dictionary:
	var idx := index if not index.is_empty() else load_index()
	if idx.has(prefab_key) and idx[prefab_key] is Dictionary:
		return idx[prefab_key]
	# suffix match
	var needle := prefab_key.get_file()
	for k in idx.keys():
		if String(k).ends_with(needle) or String(k).get_file() == needle:
			return idx[k] if idx[k] is Dictionary else {}
	return {}

static func build_prefab(prefab_key: String, source_root: String = "", index: Dictionary = {}) -> Node3D:
	var payload := payload_for(prefab_key, index)
	if payload.is_empty():
		return null
	var root := source_root
	if root.is_empty():
		var assets: Node = Engine.get_main_loop().root.get_node_or_null("/root/LunexAssets") if Engine.get_main_loop() else null
		if assets:
			root = String(assets.source_root)
	return ParticlePreview.build(payload, root)

static func build_class_attack(actor_id: String, source_root: String = "") -> Node3D:
	var key: String = String(CLASS_ATTACK_PREFABS.get(actor_id, ""))
	if key.is_empty():
		return null
	return build_prefab(key, source_root)

static func build_hurt(source_root: String = "") -> Node3D:
	return build_prefab(HURT_PREFAB, source_root)
