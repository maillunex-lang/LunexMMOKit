@tool
extends VBoxContainer
## Kit library dock: search + list of PackedScene kits for drag placement.

var plugin: EditorPlugin

@onready var _search: LineEdit = %Search
@onready var _list: ItemList = %KitList
@onready var _status: Label = %Status

const KIT_DIR := "res://world/library/kits/"

var _kits: PackedStringArray = []

func _ready() -> void:
	_refresh()
	if _search:
		_search.text_changed.connect(func(_t): _filter())
	if _list:
		_list.item_activated.connect(_on_item_activated)

func _refresh() -> void:
	_kits = PackedStringArray()
	var dir := DirAccess.open(KIT_DIR)
	if dir == null:
		_status.text = "No kits at " + KIT_DIR
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tscn"):
			_kits.append(f.get_basename())
		f = dir.get_next()
	dir.list_dir_end()
	_kits.sort()
	_filter()
	_status.text = "%d kits" % _kits.size()

func _filter() -> void:
	if _list == null:
		return
	_list.clear()
	var q := ""
	if _search:
		q = _search.text.strip_edges().to_lower()
	for id in _kits:
		if q == "" or q in id.to_lower():
			_list.add_item(id)

func _on_item_activated(index: int) -> void:
	if plugin == null:
		return
	var id := _list.get_item_text(index)
	var path := KIT_DIR + id + ".tscn"
	if not ResourceLoader.exists(path):
		_status.text = "Missing " + path
		return
	var root := plugin.get_edited_location_root() if plugin.has_method("get_edited_location_root") else null
	if root == null:
		_status.text = "Open a location .tscn first"
		return
	var ur: EditorUndoRedoManager = plugin.get_undo_redo()
	var packed: PackedScene = load(path)
	ur.create_action("Place kit " + id)
	ur.add_do_method(self, "_do_place", root, packed, id)
	ur.add_undo_method(self, "_undo_place_by_name", root, id)
	ur.commit_action()

func _do_place(root: Node3D, packed: PackedScene, id: String) -> void:
	var n: Node3D = packed.instantiate()
	n.name = id + "_" + str(Time.get_ticks_msec())
	n.set_meta("kit_id", id)
	n.set_meta("stable_id", "%s_%d" % [id, Time.get_unix_time_from_system()])
	n.set_meta("editable", true)
	root.add_child(n)
	n.owner = root
	n.position = Vector3(0, 0.05, 0)
	_snap_to_ground(n)
	root.set_meta("owner_edited", true)
	_status.text = "Placed " + n.name

func _undo_place_by_name(root: Node3D, id_prefix: String) -> void:
	for c in root.get_children():
		if String(c.name).begins_with(id_prefix + "_"):
			c.queue_free()
			return

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
