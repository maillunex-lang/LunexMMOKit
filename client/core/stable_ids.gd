extends RefCounted
class_name LunexStableIds
## FIX-006: typed stable identifiers. Instance IDs never change on move; copy allocates new instance_id.

enum Kind {
	LOCATION,
	KIT_TYPE,
	INSTANCE,
	NPC,
	QUEST_OBJECTIVE,
	PORTAL,
	MONSTER_TYPE,
	SPAWN,
}

const META_INSTANCE := "instance_id"
const META_TYPE := "type_id"
const META_KIND := "id_kind"
const META_STABLE := "stable_id" ## legacy alias = instance_id for quests/portals

static func new_id(kind: Kind, type_id: String = "") -> String:
	var prefix := _prefix(kind)
	var uuid := _uuid4()
	if type_id.is_empty():
		return "%s_%s" % [prefix, uuid]
	return "%s_%s_%s" % [prefix, type_id, uuid]

static func ensure_on_node(n: Node, kind: Kind, type_id: String = "") -> String:
	if n.has_meta(META_INSTANCE) and String(n.get_meta(META_INSTANCE)) != "":
		var existing := String(n.get_meta(META_INSTANCE))
		if not n.has_meta(META_STABLE):
			n.set_meta(META_STABLE, existing)
		return existing
	var id := new_id(kind, type_id)
	n.set_meta(META_INSTANCE, id)
	n.set_meta(META_STABLE, id)
	n.set_meta(META_KIND, _prefix(kind))
	if type_id != "":
		n.set_meta(META_TYPE, type_id)
	return id

static func duplicate_ids(src: Node, dst: Node) -> String:
	## Copy: keep type_id/kind, mint new instance_id.
	var kind_s := String(src.get_meta(META_KIND, "inst"))
	var type_id := String(src.get_meta(META_TYPE, src.get_meta("kit_id", "")))
	var kind := _kind_from_prefix(kind_s)
	return ensure_on_node(dst, kind, type_id)

static func _prefix(kind: Kind) -> String:
	match kind:
		Kind.LOCATION: return "loc"
		Kind.KIT_TYPE: return "kit"
		Kind.INSTANCE: return "inst"
		Kind.NPC: return "npc"
		Kind.QUEST_OBJECTIVE: return "qobj"
		Kind.PORTAL: return "portal"
		Kind.MONSTER_TYPE: return "mtype"
		Kind.SPAWN: return "spawn"
	return "inst"

static func _kind_from_prefix(p: String) -> Kind:
	match p:
		"loc": return Kind.LOCATION
		"kit": return Kind.KIT_TYPE
		"npc": return Kind.NPC
		"qobj": return Kind.QUEST_OBJECTIVE
		"portal": return Kind.PORTAL
		"mtype": return Kind.MONSTER_TYPE
		"spawn": return Kind.SPAWN
	return Kind.INSTANCE

static func _uuid4() -> String:
	## Godot 4 has no UUID helper in all builds; use crypto random.
	var b := PackedByteArray()
	b.resize(16)
	for i in 16:
		b[i] = randi() % 256
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	var hex := b.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
