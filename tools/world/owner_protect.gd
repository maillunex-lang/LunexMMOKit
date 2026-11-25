extends RefCounted
## FIX-004: generators must never overwrite owner-editable scenes.
## Convention:
##   foo_generated.tscn  — regenerable
##   foo.tscn / foo_owner.tscn — owner-editable; require --force-overwrite AND confirmation file
##   foo.owner.lock — sidecar written by World Editor

static func is_owner_path(path: String) -> bool:
	var base := path.get_file()
	if base.ends_with("_generated.tscn"):
		return false
	if base.ends_with("_owner.tscn"):
		return true
	if FileAccess.file_exists(ProjectSettings.globalize_path(path).get_basename() + ".owner.lock"):
		return true
	return not base.ends_with("_generated.tscn")

static func refuse_overwrite(out_res_path: String, force: bool = false) -> Dictionary:
	## Returns {ok:bool, reason:String}. ok=true means safe to write.
	var abs := ProjectSettings.globalize_path(out_res_path)
	var lock_path := abs.get_basename() + ".owner.lock"
	var confirm := abs.get_basename() + ".force_overwrite_confirm"
	if FileAccess.file_exists(lock_path):
		if not force:
			return {"ok": false, "reason": "OWNER_LOCK " + lock_path}
		if not FileAccess.file_exists(confirm):
			return {"ok": false, "reason": "NEED_CONFIRM create " + confirm + " with text YES"}
		var text := FileAccess.get_file_as_string(confirm).strip_edges()
		if text != "YES":
			return {"ok": false, "reason": "CONFIRM_NOT_YES"}
	if FileAccess.file_exists(abs):
		var existing := load(out_res_path) as PackedScene
		if existing:
			var probe: Node = existing.instantiate()
			var edited := probe and probe.has_meta("owner_edited") and bool(probe.get_meta("owner_edited"))
			if probe:
				probe.free()
			if edited and not force:
				return {"ok": false, "reason": "OWNER_EDITED meta on " + out_res_path}
			if edited and force and not FileAccess.file_exists(confirm):
				return {"ok": false, "reason": "NEED_CONFIRM for owner_edited scene"}
	# Prefer writing generated sibling when targeting owner path without force
	if is_owner_path(out_res_path) and not force:
		var gen := out_res_path.get_basename()
		if not gen.ends_with("_generated"):
			gen = gen + "_generated.tscn"
			return {"ok": false, "reason": "WRITE_GENERATED_INSTEAD " + gen, "generated": gen}
	return {"ok": true, "reason": ""}

static func generated_sibling(owner_path: String) -> String:
	var base := owner_path.get_basename()
	if base.ends_with("_generated"):
		return owner_path
	if base.ends_with("_owner"):
		base = base.substr(0, base.length() - 6)
	return base + "_generated.tscn"
