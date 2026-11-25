extends SceneTree
const Cache = preload("res://core/studio_cache.gd")
func _initialize():
	var root_path := OS.get_environment("LUNEX_STUDIO_CACHE")
	var ok := Cache.verify(root_path)
	print("cache_valid=",ok)
	var data := Cache.manifest(root_path)
	var entry: Dictionary = data.files[0].duplicate()
	entry.sha256 = "invalid"
	var rejects := not Cache.verify_file(root_path,entry) and not Cache.valid_path("../escape")
	print("rejects_invalid=",rejects)
	quit(0 if ok and rejects else 1)
