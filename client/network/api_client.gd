extends RefCounted
class_name LunexAPIClient
## HTTP client stub for authoritative server (N01 prep). LOCAL until lunexd is reachable.

signal error(message: String)

var base_url := "http://127.0.0.1:18080"
var token := ""
var protocol_version := 1

func configure(url: String) -> void:
	base_url = url.trim_suffix("/")

func register(login: String, password: String) -> Dictionary:
	return _post("/v1/register", {"login": login, "password": password})

func login(login: String, password: String) -> Dictionary:
	var res := _post("/v1/login", {"login": login, "password": password})
	if res.get("ok", false):
		token = String(res.get("token", ""))
		protocol_version = int(res.get("protocol_version", 1))
	return res

func list_characters() -> Dictionary:
	return _req(HTTPClient.METHOD_GET, "/v1/characters", {})

func create_character(name: String, class_actor_id: String = "10001") -> Dictionary:
	return _post("/v1/characters", {"name": name, "class_actor_id": class_actor_id})

func _post(path: String, body: Dictionary) -> Dictionary:
	return _req(HTTPClient.METHOD_POST, path, body)

func _req(method: int, path: String, body: Dictionary) -> Dictionary:
	## Synchronous helper for headless tests; game UI should use HTTPRequest node later.
	var http := HTTPClient.new()
	var url := base_url + path
	var host := base_url.trim_prefix("http://").trim_prefix("https://")
	var port := 80
	if ":" in host:
		var parts := host.split(":")
		host = parts[0]
		port = int(parts[1])
	var err := http.connect_to_host(host, port)
	if err != OK:
		return {"ok": false, "error": "connect %s" % err}
	var deadline := Time.get_ticks_msec() + 5000
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		if Time.get_ticks_msec() > deadline:
			return {"ok": false, "error": "connect timeout"}
		OS.delay_msec(10)
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"ok": false, "error": "not connected"}
	var headers := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		headers.append("Authorization: Bearer " + token)
	var payload := PackedByteArray()
	if method != HTTPClient.METHOD_GET:
		payload = JSON.stringify(body).to_utf8_buffer()
	err = http.request(method, path, headers, payload.get_string_from_utf8() if payload.size() else "")
	if err != OK:
		return {"ok": false, "error": "request %s" % err}
	deadline = Time.get_ticks_msec() + 5000
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		if Time.get_ticks_msec() > deadline:
			return {"ok": false, "error": "request timeout"}
		OS.delay_msec(10)
	if not http.has_response():
		return {"ok": false, "error": "no response"}
	var code := http.get_response_code()
	var rb := PackedByteArray()
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll()
		var chunk := http.read_response_body_chunk()
		if chunk.size():
			rb.append_array(chunk)
		else:
			OS.delay_msec(5)
	var text := rb.get_string_from_utf8()
	var parsed = JSON.parse_string(text) if text != "" else {}
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "bad json", "status": code, "raw": text}
	var d: Dictionary = parsed
	d["status"] = code
	return d
