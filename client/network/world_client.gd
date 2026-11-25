extends RefCounted
## N02/C01 HTTP world client (join/move/snapshot/attack). Presentation only — server owns state.

const API = preload("res://network/api_client.gd")
const Interpolator = preload("res://network/entity_interpolator.gd")

var api
var interp := Interpolator.new()
var self_id := 0
var last_snapshot: Array = []

func _init(client = null) -> void:
	api = client if client != null else API.new()

func configure(url: String) -> void:
	api.configure(url)

func join(name: String, class_actor_id: String, location: String, pos: Vector3) -> Dictionary:
	return api.world_join(name, class_actor_id, location, {"x": pos.x, "y": pos.y, "z": pos.z})

func move(pos: Vector3, yaw: float, dt: float) -> Dictionary:
	return api.world_move({"x": pos.x, "y": pos.y, "z": pos.z}, yaw, dt)

func snapshot() -> Dictionary:
	var res: Dictionary = api.world_snapshot()
	if res.get("ok", false):
		last_snapshot = res.get("entities", [])
		self_id = int(res.get("self_id", self_id))
		interp.push_snapshot(last_snapshot)
	return res

func attack(target_id: int, skill_id: String = "basic", client_damage: int = 0) -> Dictionary:
	## client_damage is sent only to prove server ignores it (C01).
	return api.world_attack(target_id, skill_id, client_damage)
