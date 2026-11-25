@tool
extends VBoxContainer
## Kit library dock: categories, search, place, markers, material override, shared export (WE03).

var plugin: EditorPlugin

@onready var _search: LineEdit = %Search
@onready var _list: ItemList = %KitList
@onready var _status: Label = %Status
@onready var _preview: Label = %Preview
@onready var _place_btn: Button = %PlaceBtn
@onready var _btn_npc: Button = %BtnNpc
@onready var _btn_portal: Button = %BtnPortal
@onready var _btn_spawn: Button = %BtnSpawn
@onready var _btn_mat: Button = %BtnMat
@onready var _btn_export: Button = %BtnExport

const KIT_DIR := "res://world/library/kits/"
const MARKER_DIR := "res://world/library/markers/"
const StableIds = preload("res://core/stable_ids.gd")

var _kits: PackedStringArray = []
var _categories: Dictionary = {} ## category -> Array[String]

func _ready() -> void:
	_refresh()
	if _search:
		_search.text_changed.connect(func(_t): _filter())
	if _list:
		_list.item_activated.connect(_on_item_activated)
		_list.item_selected.connect(_on_item_selected)
	if _place_btn:
		_place_btn.pressed.connect(_on_place_pressed)
	if _btn_npc:
		_btn_npc.pressed.connect(func(): _place_marker("npc_marker", StableIds.Kind.NPC, "npc_role", "quest"))
	if _btn_portal:
		_btn_portal.pressed.connect(func(): _place_marker("portal_marker", StableIds.Kind.PORTAL, "portal_id", ""))
	if _btn_spawn:
		_btn_spawn.pressed.connect(func(): _place_marker("spawn_marker", StableIds.Kind.SPAWN, "respawn_id", "player"))
	if _btn_mat:
		_btn_mat.pressed.connect(_on_material_override)
	if _btn_export:
		_btn_export.pressed.connect(_on_export_shared)

func _refresh() -> void:
	_kits = PackedStringArray()
	_categories.clear()
	_scan_dir(KIT_DIR)
	_scan_dir(MARKER_DIR)
	_kits.sort()
	_filter()
	_status.text = "%d kits / %d categories" % [_kits.size(), _categories.size()]

func _scan_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tscn"):
			var id := f.get_basename()
			if id not in _kits:
				_kits.append(id)
			var cat := _category_of(id)
			if not _categories.has(cat):
				_categories[cat] = []
			if id not in _categories[cat]:
				_categories[cat].append(id)
		f = dir.get_next()
	dir.list_dir_end()

func _category_of(id: String) -> String:
	var lower := id.to_lower()
	if lower.contains("marker") or lower.begins_with("npc"):
		return "Markers"
	if lower.contains("portal") or lower.contains("gate"):
		return "Portals"
	if lower.contains("spawn"):
		return "Spawns"
	if lower.contains("tree") or lower.contains("bush") or lower.contains("rock") or lower.contains("grass"):
		return "Nature"
	if lower.contains("stall") or lower.contains("market") or lower.contains("barrel") or lower.contains("crate"):
		return "Props"
	if lower.contains("building") or lower.contains("wall") or lower.contains("house") or lower.contains("tower") or lower.contains("palace") or lower.contains("shop"):
		return "Buildings"
	if lower.contains("road") or lower.contains("tile") or lower.contains("ground") or lower.contains("bridge"):
		return "Ground"
	return "Misc"

func _filter() -> void:
	if _list == null:
		return
	_list.clear()
	var q := ""
	if _search:
		q = _search.text.strip_edges().to_lower()
	var keys: Array = _categories.keys()
	keys.sort()
	for cat in keys:
		var any := false
		var items: Array = _categories[cat]
		items.sort()
		for id in items:
			if q == "" or q in id.to_lower() or q in String(cat).to_lower():
				if not any:
					_list.add_item("— " + String(cat) + " —")
					_list.set_item_disabled(_list.item_count - 1, true)
					any = true
				_list.add_item(id)
				_list.set_item_metadata(_list.item_count - 1, id)

func _on_item_selected(index: int) -> void:
	if _list.is_item_disabled(index):
		return
	var id := _selected_kit_id(index)
	if id.is_empty():
		return
	if _preview:
		_preview.text = "Кит: %s\nPlace / двойной клик — в сцену (snap). Затем Q/W/E/R." % id

func _on_place_pressed() -> void:
	if _list == null:
		return
	var sel := _list.get_selected_items()
	if sel.is_empty():
		_status.text = "Выберите кит в списке"
		return
	_place_kit(_selected_kit_id(sel[0]))

func _selected_kit_id(index: int) -> String:
	if _list.is_item_disabled(index):
		return ""
	var id := String(_list.get_item_metadata(index))
	if id.is_empty():
		id = _list.get_item_text(index)
	if id.begins_with("—"):
		return ""
	return id

func _on_item_activated(index: int) -> void:
	_place_kit(_selected_kit_id(index))

func _resolve_kit_path(id: String) -> String:
	var p1 := KIT_DIR + id + ".tscn"
	if ResourceLoader.exists(p1):
		return p1
	var p2 := MARKER_DIR + id + ".tscn"
	if ResourceLoader.exists(p2):
		return p2
	return ""

func _place_kit(id: String) -> void:
	if plugin == null or id.is_empty():
		return
	var path := _resolve_kit_path(id)
	if path == "":
		_status.text = "Missing kit " + id
		return
	var root := plugin.get_edited_location_root() if plugin.has_method("get_edited_location_root") else null
	if root == null:
		_status.text = "Open a location .tscn first"
		return
	var packed: PackedScene = load(path)
	var n: Node3D = packed.instantiate()
	n.name = id + "_" + str(Time.get_ticks_msec())
	n.set_meta("kit_id", id)
	n.set_meta("editable", true)
	StableIds.ensure_on_node(n, StableIds.Kind.INSTANCE, id)
	n.position = _placement_origin(root)
	var ur: EditorUndoRedoManager = plugin.get_undo_redo()
	ur.create_action("Place kit " + id)
	ur.add_do_method(self, "_do_add", root, n)
	ur.add_undo_method(self, "_do_remove", root, n)
	ur.add_do_reference(n)
	ur.commit_action()
	if plugin.has_method("get_editor_interface"):
		var ei = plugin.get_editor_interface()
		ei.get_selection().clear()
		ei.get_selection().add_node(n)
	_status.text = "Placed %s — drag gizmo / snap" % n.name

func _place_marker(kit_id: String, kind: int, meta_key: String, meta_val: String) -> void:
	if plugin == null:
		return
	var path := MARKER_DIR + kit_id + ".tscn"
	if not ResourceLoader.exists(path):
		_status.text = "Missing " + path
		return
	var root := plugin.get_edited_location_root() if plugin.has_method("get_edited_location_root") else null
	if root == null:
		_status.text = "Open a location .tscn first"
		return
	var packed: PackedScene = load(path)
	var n: Node3D = packed.instantiate()
	n.name = kit_id + "_" + str(Time.get_ticks_msec())
	n.set_meta("editable", true)
	if meta_key != "":
		n.set_meta(meta_key, meta_val if meta_val != "" else n.name)
	var sid := StableIds.ensure_on_node(n, kind, kit_id)
	if kind == StableIds.Kind.PORTAL:
		n.set_meta("portal_id", sid)
	elif kind == StableIds.Kind.SPAWN:
		n.set_meta("respawn_id", sid)
	elif kind == StableIds.Kind.NPC:
		n.set_meta("npc_role", meta_val if meta_val != "" else "quest")
	n.position = _placement_origin(root)
	var ur: EditorUndoRedoManager = plugin.get_undo_redo()
	ur.create_action("Place marker " + kit_id)
	ur.add_do_method(self, "_do_add", root, n)
	ur.add_undo_method(self, "_do_remove", root, n)
	ur.add_do_reference(n)
	ur.commit_action()
	if plugin.has_method("get_editor_interface"):
		var ei = plugin.get_editor_interface()
		ei.get_selection().clear()
		ei.get_selection().add_node(n)
	_status.text = "Marker %s id=%s" % [n.name, sid]

func _on_material_override() -> void:
	## WE03: albedo tint override on selected MeshInstance without editing GLB.
	if plugin == null or not plugin.has_method("get_editor_interface"):
		return
	var sel: Array = plugin.get_editor_interface().get_selection().get_selected_nodes()
	if sel.is_empty():
		_status.text = "Select a placed kit / MeshInstance3D"
		return
	var target: Node = sel[0]
	var mesh_inst: MeshInstance3D = target as MeshInstance3D
	if mesh_inst == null:
		mesh_inst = target.find_child("*", true, false) as MeshInstance3D
		for c in target.find_children("*", "MeshInstance3D", true, false):
			mesh_inst = c
			break
	if mesh_inst == null:
		_status.text = "No MeshInstance3D under selection"
		return
	var prev: Material = mesh_inst.get_surface_override_material(0)
	var mat := StandardMaterial3D.new()
	if prev is StandardMaterial3D:
		mat = (prev as StandardMaterial3D).duplicate() as StandardMaterial3D
	mat.albedo_color = Color(0.85, 0.7, 0.45, 1.0)
	var ur: EditorUndoRedoManager = plugin.get_undo_redo()
	ur.create_action("Material override albedo")
	ur.add_do_property(mesh_inst, "surface_material_override/0", mat)
	ur.add_undo_property(mesh_inst, "surface_material_override/0", prev)
	ur.commit_action()
	var root := plugin.get_edited_location_root()
	if root:
		_mark_owner(root)
	_status.text = "Material override applied (undoable)"

func _on_export_shared() -> void:
	if plugin == null:
		return
	var root := plugin.get_edited_location_root() if plugin.has_method("get_edited_location_root") else null
	if root == null:
		_status.text = "Open a location .tscn first"
		return
	var VALIDATOR = preload("res://addons/lunex_world_editor/location_validators.gd")
	var markers: Array = []
	for entry in VALIDATOR.collect_stable(root):
		markers.append(entry)
	# Also scan meta-bearing nodes
	for n in root.find_children("*", "Node3D", true, false):
		if n.has_meta("stable_id") or n.has_meta("instance_id") or n.has_meta("npc_role") or n.has_meta("portal_id"):
			var sid := String(n.get_meta("instance_id", n.get_meta("stable_id", n.name)))
			markers.append({
				"stable_id": sid,
				"node": String(n.get_path()),
				"pos": {"x": n.global_position.x, "y": n.global_position.y, "z": n.global_position.z},
				"npc_role": String(n.get_meta("npc_role", "")),
				"portal_id": String(n.get_meta("portal_id", "")),
				"kit_id": String(n.get_meta("kit_id", "")),
			})
	var loc_id := String(root.name).to_snake_case()
	if root.scene_file_path != "":
		loc_id = root.scene_file_path.get_file().get_basename()
	var payload := {
		"location_id": loc_id,
		"location_revision": int(root.get_meta("location_revision", 0)),
		"scene": root.scene_file_path,
		"markers": markers,
	}
	var out_res := "res://content/locations/%s_shared.json" % loc_id
	var abs := ProjectSettings.globalize_path(out_res)
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(out_res, FileAccess.WRITE)
	if f == null:
		_status.text = "Cannot write " + out_res
		return
	f.store_string(JSON.stringify(payload, "\t"))
	_mark_owner(root)
	_status.text = "Exported %s (%d markers)" % [out_res, markers.size()]

func _placement_origin(root: Node3D) -> Vector3:
	var sel_nodes: Array = []
	if plugin and plugin.has_method("get_editor_interface"):
		sel_nodes = plugin.get_editor_interface().get_selection().get_selected_nodes()
	for s in sel_nodes:
		if s is Node3D and s != root:
			var p: Vector3 = (s as Node3D).global_position
			return root.to_local(p + Vector3(2, 0.05, 0))
	if plugin and plugin.has_method("get_editor_interface"):
		var cam = plugin.get_editor_interface().get_editor_viewport_3d(0).get_camera_3d()
		if cam:
			var hit: Vector3 = cam.global_position - cam.global_basis.z * 8.0
			hit.y = 0.05
			return root.to_local(hit)
	return Vector3(0, 0.05, 0)

func _do_add(root: Node3D, n: Node3D) -> void:
	if n.get_parent() != root:
		if n.get_parent():
			n.get_parent().remove_child(n)
		root.add_child(n)
	n.owner = root
	_snap_to_ground(n)
	_mark_owner(root)
	_status.text = "Placed %s (%s)" % [n.name, String(n.get_meta("instance_id", ""))]

func _do_remove(root: Node3D, n: Node3D) -> void:
	if n.get_parent() == root:
		root.remove_child(n)
	_mark_owner(root)
	_status.text = "Removed " + n.name

func _mark_owner(root: Node3D) -> void:
	root.set_meta("owner_edited", true)
	var path := root.scene_file_path
	if path != "" and path.begins_with("res://"):
		var abs := ProjectSettings.globalize_path(path)
		var lock := abs.get_basename() + ".owner.lock"
		var f := FileAccess.open(lock, FileAccess.WRITE)
		if f:
			f.store_string("owner_edited=true\nupdated=%s\n" % Time.get_datetime_string_from_system())

func _snap_to_ground(n: Node3D) -> void:
	var space := n.get_world_3d().direct_space_state if n.get_world_3d() else null
	if space == null:
		return
	var from := n.global_position + Vector3(0, 50, 0)
	var to := n.global_position + Vector3(0, -200, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [n.get_instance_id()]
	var hit := space.intersect_ray(q)
	if hit:
		n.global_position = hit.position + Vector3(0, 0.02, 0)
