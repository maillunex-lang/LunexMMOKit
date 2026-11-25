extends RefCounted
static func valid_path(path: String) -> bool:
	return not path.is_empty() and not path.is_absolute_path() and not path.contains("..") and not path.contains(":") and not path.contains("\\")
static func verify_file(root: String, entry: Dictionary) -> bool:
	var path := String(entry.get("path",""))
	if not valid_path(path): return false
	var file := FileAccess.open(root.path_join(path),FileAccess.READ)
	if file == null: return false
	var length := file.get_length()
	file.close()
	return length == int(entry.get("size",-1)) and FileAccess.get_sha256(root.path_join(path)) == String(entry.get("sha256",""))
static func manifest(root: String) -> Dictionary:
	var value = JSON.parse_string(FileAccess.get_file_as_string(root.path_join("manifest.json")))
	if not value is Dictionary or value.get("version") != 1 or not value.get("files") is Array: return {}
	if value.files.is_empty(): return {}
	for entry in value.files:
		if not entry is Dictionary or not valid_path(String(entry.get("path",""))): return {}
	return value
static func verify(root: String) -> bool:
	var data := manifest(root)
	if data.is_empty(): return false
	for entry in data.files:
		if not verify_file(root,entry): return false
	return true
