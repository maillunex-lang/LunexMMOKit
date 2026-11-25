extends RefCounted

const OffsetScript = preload("res://actors/attachment_offset.gd")
const DEFAULT_DIR := "res://content/attachments"
const OVERRIDE_DIR := "user://attachments/overrides"

static func _key(kind: String, equipment_id: String, class_id: String = "", child_name: String = "") -> String:
	var parts: PackedStringArray = [kind, equipment_id]
	if class_id != "":
		parts.append(class_id)
	if child_name != "":
		parts.append(child_name)
	return "_".join(parts)

static func _path_for(dir: String, key: String) -> String:
	return dir.path_join(key + ".tres")

static func _is_offset(res: Resource) -> bool:
	return res != null and res.get_script() == OffsetScript

static func load_offset(kind: String, equipment_id: String, class_id: String = "", child_name: String = "") -> Resource:
	var key := _key(kind, equipment_id, class_id, child_name)
	var override_path := _path_for(OVERRIDE_DIR, key)
	if FileAccess.file_exists(override_path):
		var ov := load(override_path)
		if _is_offset(ov):
			return ov
	# class-specific default then generic default
	if class_id != "":
		var class_path := _path_for(DEFAULT_DIR, _key(kind, equipment_id, class_id, child_name))
		if ResourceLoader.exists(class_path):
			var c := load(class_path)
			if _is_offset(c):
				return c
	var path := _path_for(DEFAULT_DIR, _key(kind, equipment_id, "", child_name))
	if ResourceLoader.exists(path):
		var res := load(path)
		if _is_offset(res):
			return res
	return null

static func save_override(offset: Resource) -> Error:
	if not _is_offset(offset):
		return ERR_INVALID_PARAMETER
	DirAccess.make_dir_recursive_absolute(OVERRIDE_DIR)
	var key := _key(offset.kind, offset.equipment_id, offset.class_id, offset.child_name)
	return ResourceSaver.save(offset, _path_for(OVERRIDE_DIR, key))

static func reset_override(kind: String, equipment_id: String, class_id: String = "", child_name: String = "") -> bool:
	var path := _path_for(OVERRIDE_DIR, _key(kind, equipment_id, class_id, child_name))
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path) == OK
	return false

static func list_defaults() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(DEFAULT_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			out.append(DEFAULT_DIR.path_join(name))
		name = dir.get_next()
	return out
