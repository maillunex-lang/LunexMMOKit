@tool
extends VBoxContainer
## Kit library dock: categories, search, place with instance Undo/Redo (FIX-003/006/011).

var plugin: EditorPlugin

@onready var _search: LineEdit = %Search
@onready var _list: ItemList = %KitList
@onready var _status: Label = %Status
@onready var _preview: Label = %Preview
@onready var _place_btn: Button = %PlaceBtn

const KIT_DIR := "res://world/library/kits/"
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

func _refresh() -> void:
	_kits = PackedStringArray()
	_categories.clear()
	var dir := DirAccess.open(KIT_DIR)
	if dir == null:
		_status.text = "No kits at " + KIT_DIR
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tscn"):
			var id := f.get_basename()
			_kits.append(id)
			var cat := _category_of(id)
			if not _categories.has(cat):
				_categories[cat] = []
			_categories[cat].append(id)
		f = dir.get_next()
	dir.list_dir_end()
	_kits.sort()
	_filter()
	_status.text = "%d kits / %d categories" % [_kits.size(), _categories.size()]

func _category_of(id: String) -> String:
	var lower := id.to_lower()
	if lower.begins_with("npc") or lower.contains("guard") or lower.contains("vendor"):
		return "NPC"
	if lower.contains("portal") or lower.contains("gate"):
		return "Portals"
	if lower.contains("spawn"):
		return "Spawns"
	if lower.contains("tree") or lower.contains("bush") or lower.contains("rock") or lower.contains("grass"):
		return "Nature"
	if lower.contains("stall") or lower.contains("market") or lower.contains("barrel") or lower.contains("crate"):
		return "Props"
	if lower.contains("building") or lower.contains("wall") or lower.contains("house") or lower.contains("tower"):
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
		_preview.text = "Кит: %s\nres://world/library/kits/%s.tscn\nPlace / двойной клик — в сцену (snap к земле)" % [id, id]

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

func _place_kit(id: String) -> void:
	if plugin == null or id.is_empty():
		return
	var path := KIT_DIR + id + ".tscn"
	if not ResourceLoader.exists(path):
		_status.text = "Missing " + path
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
	## FIX-011: place near current 3D editor selection / camera look, then snap to ground.
	n.position = _placement_origin(root)
	var ur: EditorUndoRedoManager = plugin.get_undo_redo()
	ur.create_action("Place kit " + id)
	ur.add_do_method(self, "_do_add", root, n)
	ur.add_undo_method(self, "_do_remove", root, n)
	ur.add_do_reference(n) ## keep instance alive across undo/redo
	ur.commit_action()
	# Select new instance so owner can drag in 3D viewport (Godot native DnD).
	if plugin.has_method("get_editor_interface"):
		var ei = plugin.get_editor_interface()
		ei.get_selection().clear()
		ei.get_selection().add_node(n)
		_status.text = "Placed %s — drag in 3D viewport / gizmo" % n.name

func _placement_origin(root: Node3D) -> Vector3:
	var sel_nodes: Array = []
	if plugin and plugin.has_method("get_editor_interface"):
		sel_nodes = plugin.get_editor_interface().get_selection().get_selected_nodes()
	for s in sel_nodes:
		if s is Node3D and s != root:
			var p: Vector3 = (s as Node3D).global_position
			return root.to_local(p + Vector3(2, 0.05, 0))
	# Fallback: in front of editor camera if available
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
	# Touch sidecar lock so generators refuse overwrite (FIX-004).
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
