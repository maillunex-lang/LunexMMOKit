extends RefCounted
## W02: location catalog — scenes, spawns, safe zones, map AABB for minimap.

const LOCATIONS := {
	"eternity_capital": {
		"name": "Столица Вечности",
		"scene": "res://world/locations/eternity_capital/eternity_play.tscn",
		"spawn": Vector3(0, 1, -60),
		"safe_zone": {"center": Vector3(0, 0, -20), "radius": 80.0},
		"map_bounds": {"min": Vector3(-100, -5, -100), "max": Vector3(100, 40, 100)},
		"portals": {
			"portal_ashen_gate": {"target": "ashen_outskirts", "landing": Vector3(0, 1, -8)},
		},
	},
	"ashen_outskirts": {
		"name": "Пепельный рубеж",
		"scene": "res://world/locations/ashen_outskirts/ashen_play.tscn",
		"spawn": Vector3(0, 1, -8),
		"safe_zone": {"center": Vector3(0, 0, 0), "radius": 25.0},
		"map_bounds": {"min": Vector3(-60, -5, -60), "max": Vector3(60, 30, 60)},
		"portals": {
			"portal_capital_return": {"target": "eternity_capital", "landing": Vector3(0, 1, -55)},
			"portal_ruins_gate": {"target": "shard_ruins", "landing": Vector3(0, 1, 0)},
		},
	},
	"shard_ruins": {
		"name": "Руины Осколка",
		"scene": "res://world/locations/shard_ruins/ruins_play.tscn",
		"spawn": Vector3(0, 1, 0),
		"safe_zone": {"center": Vector3(0, 0, 0), "radius": 18.0},
		"map_bounds": {"min": Vector3(-40, -5, -40), "max": Vector3(40, 30, 40)},
		"portals": {
			"portal_ashen_return": {"target": "ashen_outskirts", "landing": Vector3(0, 1, 10)},
		},
	},
	"route_corridor": {
		"name": "Тестовый коридор",
		"scene": "res://world/route_corridor/route_play.tscn",
		"spawn": Vector3(0, 1, 2),
		"safe_zone": {"center": Vector3(0, 0, 2), "radius": 15.0},
		"map_bounds": {"min": Vector3(-20, -5, 0), "max": Vector3(20, 20, 650)},
		"portals": {},
	},
}

static func has(location_id: String) -> bool:
	return LOCATIONS.has(location_id)

static func entry(location_id: String) -> Dictionary:
	return LOCATIONS.get(location_id, {}) if LOCATIONS.has(location_id) else {}

static func scene_path(location_id: String) -> String:
	return String(entry(location_id).get("scene", ""))

static func spawn_point(location_id: String) -> Vector3:
	var e := entry(location_id)
	var s: Variant = e.get("spawn", Vector3.ZERO)
	return s if s is Vector3 else Vector3.ZERO

static func safe_zone(location_id: String) -> Dictionary:
	var e := entry(location_id)
	return e.get("safe_zone", {}) if e.get("safe_zone", {}) is Dictionary else {}

static func in_safe_zone(location_id: String, pos: Vector3) -> bool:
	var z := safe_zone(location_id)
	if z.is_empty():
		return false
	var c: Vector3 = z.get("center", Vector3.ZERO)
	var r := float(z.get("radius", 0.0))
	return Vector2(pos.x - c.x, pos.z - c.z).length() <= r

static func portal_landing(from_location: String, portal_id: String) -> Dictionary:
	## Returns {ok, target, landing}
	var e := entry(from_location)
	var portals: Dictionary = e.get("portals", {})
	if not portals.has(portal_id):
		return {"ok": false}
	var p: Dictionary = portals[portal_id]
	return {
		"ok": true,
		"target": String(p.get("target", "")),
		"landing": p.get("landing", spawn_point(String(p.get("target", "")))),
	}

static func world_to_map_uv(location_id: String, pos: Vector3) -> Vector2:
	var e := entry(location_id)
	var b: Dictionary = e.get("map_bounds", {})
	if b.is_empty():
		return Vector2(0.5, 0.5)
	var mn: Vector3 = b.get("min", Vector3(-1, 0, -1))
	var mx: Vector3 = b.get("max", Vector3(1, 0, 1))
	var u := 0.5
	var v := 0.5
	if absf(mx.x - mn.x) > 0.001:
		u = clampf((pos.x - mn.x) / (mx.x - mn.x), 0.0, 1.0)
	if absf(mx.z - mn.z) > 0.001:
		v = clampf((pos.z - mn.z) / (mx.z - mn.z), 0.0, 1.0)
	return Vector2(u, v)

static func ids() -> PackedStringArray:
	return PackedStringArray(LOCATIONS.keys())
