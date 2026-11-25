extends Node
## FIX-002: portable asset resolution for game runtime.
## Order: explicit override → bundled assets/studio → user:// cache → (tools only) env absolute roots.
## Never hardcode /home/gamedev in play scenes.

const USER_CACHE := "user://studio-cache-v2"
const BUNDLED_REL := "res://../assets/studio"

var cache_root: String = ""
var source_root: String = ""
var ready_ok := false

func _ready() -> void:
	refresh()

func refresh() -> void:
	cache_root = ""
	var env_cache := OS.get_environment("LUNEX_STUDIO_CACHE").strip_edges()
	if not env_cache.is_empty() and DirAccess.dir_exists_absolute(env_cache):
		cache_root = env_cache
	elif not OS.has_feature("android"):
		var bundled := ProjectSettings.globalize_path(BUNDLED_REL)
		if FileAccess.file_exists(bundled.path_join("manifest.json")):
			cache_root = bundled
	if cache_root.is_empty():
		var user_abs := ProjectSettings.globalize_path(USER_CACHE)
		if FileAccess.file_exists(user_abs.path_join("manifest.json")):
			cache_root = user_abs
		elif DirAccess.dir_exists_absolute(user_abs):
			cache_root = user_abs
	# Tools/dev may set original Darklord root; game runtime must not require it.
	source_root = OS.get_environment("LUNEX_DARKLORD_ROOT").strip_edges()
	if source_root.is_empty() and not cache_root.is_empty():
		var nested := cache_root.path_join("source")
		if DirAccess.dir_exists_absolute(nested):
			source_root = nested
	ready_ok = not cache_root.is_empty()

func exports_dir() -> String:
	return cache_root.path_join("exports") if not cache_root.is_empty() else ""

func actor_glb(actor_id: String) -> String:
	return _first_existing([
		exports_dir().path_join("%s.glb" % actor_id) if not exports_dir().is_empty() else "",
		"res://content/runtime/actors/%s.glb" % actor_id,
	])

func weapon_glb(weapon_id: String) -> String:
	return _first_existing([
		exports_dir().path_join("weapon-%s.glb" % weapon_id) if not exports_dir().is_empty() else "",
		"res://content/runtime/weapons/weapon-%s.glb" % weapon_id,
	])

func material_params_path() -> String:
	return _first_existing([
		cache_root.path_join("material-params.json") if not cache_root.is_empty() else "",
		"res://content/runtime/material-params.json",
	])

func particle_index_path() -> String:
	return _first_existing([
		cache_root.path_join("particle-index.json") if not cache_root.is_empty() else "",
		"res://content/runtime/particle-index.json",
	])

func accessory_root() -> String:
	if not exports_dir().is_empty():
		var p := exports_dir().path_join("accessories")
		if DirAccess.dir_exists_absolute(p):
			return p
	return ""

func resolve_source_texture(rel: String) -> String:
	## Prefer cached/bundled copies; absolute Darklord only if LUNEX_DARKLORD_ROOT set (tools).
	if rel.is_empty():
		return ""
	var candidates: Array[String] = []
	if not cache_root.is_empty():
		candidates.append(cache_root.path_join("source").path_join(rel))
		candidates.append(cache_root.path_join(rel))
	candidates.append("res://content/runtime/source/".path_join(rel))
	if not source_root.is_empty():
		candidates.append(source_root.path_join(rel))
	return _first_existing(candidates)

func status_line() -> String:
	if ready_ok:
		return "assets: " + cache_root
	return "assets MISSING — sync assets/studio or set LUNEX_STUDIO_CACHE / run studio boot"

func _first_existing(paths: Array) -> String:
	for p in paths:
		var s := String(p)
		if s.is_empty():
			continue
		if s.begins_with("res://"):
			if ResourceLoader.exists(s) or FileAccess.file_exists(s):
				return s
		elif FileAccess.file_exists(s):
			return s
	return ""
