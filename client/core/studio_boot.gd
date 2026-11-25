extends Control
const Cache = preload("studio_cache.gd")
var label: Label
var progress: ProgressBar
var request: HTTPRequest
var base_url := ""
var cache_root := "user://studio-cache"
func _ready():
	var box := VBoxContainer.new()
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position -= Vector2(280,90)
	box.custom_minimum_size = Vector2(560,180)
	label = Label.new()
	label.text = "Проверка ресурсов..."
	box.add_child(label)
	progress = ProgressBar.new()
	box.add_child(progress)
	request = HTTPRequest.new()
	request.body_size_limit = 32*1024*1024
	request.timeout = 60
	add_child(request)
	base_url = String(ProjectSettings.get_setting("lunex/studio_asset_url","")).trim_suffix("/")
	call_deferred("install")
func install():
	var local := OS.get_environment("LUNEX_STUDIO_CACHE")
	if not local.is_empty(): cache_root = local
	if Cache.verify(cache_root):
		get_tree().change_scene_to_file("res://scenes/training/training.tscn")
		return
	if not base_url.begins_with("https://"):
		label.text = "Ресурсы отсутствуют. Сервер загрузки не настроен."
		return
	if request.request(base_url+"/manifest.json") != OK:
		label.text = "Ошибка подключения"
		return
	var result: Array = await request.request_completed
	if result[0]!=HTTPRequest.RESULT_SUCCESS or result[1]!=200:
		label.text = "Не удалось получить манифест"
		return
	var data = JSON.parse_string(result[3].get_string_from_utf8())
	if not data is Dictionary or data.get("version")!=1 or not data.get("files") is Array or data.files.is_empty():
		label.text = "Некорректный манифест"
		return
	DirAccess.make_dir_recursive_absolute(cache_root)
	progress.max_value = data.files.size()
	for entry in data.files:
		if not entry is Dictionary or not Cache.valid_path(String(entry.get("path",""))):
			label.text = "Некорректный путь ресурса"
			return
		var path := String(entry.path)
		label.text = "Загрузка %d / %d" % [int(progress.value)+1,data.files.size()]
		if not Cache.verify_file(cache_root,entry):
			var target := cache_root.path_join(path)
			DirAccess.make_dir_recursive_absolute(target.get_base_dir())
			request.download_file = target+".part"
			if request.request(base_url+"/"+path.uri_encode().replace("%2F","/")) != OK:
				label.text = "Ошибка запроса"
				return
			result = await request.request_completed
			request.download_file = ""
			if result[0]!=HTTPRequest.RESULT_SUCCESS or result[1]!=200 or FileAccess.get_sha256(target+".part")!=String(entry.sha256):
				label.text = "Ошибка загрузки или контрольной суммы"
				return
			if DirAccess.rename_absolute(target+".part",target)!=OK:
				label.text = "Ошибка сохранения"
				return
		progress.value += 1
	var file := FileAccess.open(cache_root.path_join("manifest.json"),FileAccess.WRITE)
	if file == null:
		label.text = "Ошибка записи манифеста"
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if Cache.verify(cache_root): get_tree().change_scene_to_file("res://scenes/training/training.tscn")
	else: label.text = "Проверка ресурсов не пройдена"
