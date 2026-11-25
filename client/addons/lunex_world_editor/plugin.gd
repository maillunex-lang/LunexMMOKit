@tool
extends EditorPlugin
## WORLD-EDITOR-003 + AUDIT FIX-003/005/007/011.

const DOCK_SCENE := preload("res://addons/lunex_world_editor/library_dock.tscn")
const VALIDATOR := preload("res://addons/lunex_world_editor/location_validators.gd")
const NavScript = preload("res://world/location_navigation.gd")

var _dock: Control
var _issues_panel: ItemList
var _last_issues: Array = []

func _enter_tree() -> void:
	_dock = DOCK_SCENE.instantiate()
	_dock.plugin = self
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
	_issues_panel = ItemList.new()
	_issues_panel.name = "LunexValidationIssues"
	_issues_panel.custom_minimum_size = Vector2(0, 120)
	_issues_panel.item_activated.connect(_on_issue_activated)
	if _dock.has_method("add_child"):
		_dock.add_child(_issues_panel)
	add_tool_menu_item("Lunex: Bake Location NavigationMesh", _on_bake_nav)
	add_tool_menu_item("Lunex: Validate Location", _on_validate)
	add_tool_menu_item("Lunex: Write owner.lock", _on_write_lock)
	add_tool_menu_item("Lunex: Duplicate Selected (new instance_id)", _on_duplicate_selected)

func _exit_tree() -> void:
	remove_tool_menu_item("Lunex: Bake Location NavigationMesh")
	remove_tool_menu_item("Lunex: Validate Location")
	remove_tool_menu_item("Lunex: Write owner.lock")
	remove_tool_menu_item("Lunex: Duplicate Selected (new instance_id)")
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

func get_edited_location_root() -> Node3D:
	var edited := get_editor_interface().get_edited_scene_root()
	return edited as Node3D

func _on_write_lock() -> void:
	var root := get_edited_location_root()
	if root == null:
		return
	root.set_meta("owner_edited", true)
	var path := root.scene_file_path
	if path == "":
		push_warning("Save the scene before writing owner.lock")
		return
	var abs := ProjectSettings.globalize_path(path)
	# FIX-004: timestamped backup before locking / further generator risk
	var bak_dir := abs.get_base_dir().path_join("backups")
	DirAccess.make_dir_recursive_absolute(bak_dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace(" ", "_")
	var bak := bak_dir.path_join(abs.get_file().get_basename() + "_" + stamp + ".tscn")
	var src := FileAccess.get_file_as_bytes(abs)
	if src.size() > 0:
		var out := FileAccess.open(bak, FileAccess.WRITE)
		if out:
			out.store_buffer(src)
			print("Lunex World Editor: backup ", bak)
	var lock := abs.get_basename() + ".owner.lock"
	var f := FileAccess.open(lock, FileAccess.WRITE)
	if f:
		f.store_string("owner_edited=true\nscene=%s\nbackup=%s\n" % [path, bak])
		print("Lunex World Editor: wrote ", lock)

func _on_bake_nav() -> void:
	var root := get_edited_location_root()
	if root == null:
		push_warning("Lunex World Editor: open a Node3D location scene first.")
		return
	var region := root.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	if region == null:
		region = root.find_child("Navigation", true, false) as NavigationRegion3D
	var prev_mesh: NavigationMesh = null
	var prev_rev := int(root.get_meta("location_revision", 0))
	if region and region.navigation_mesh:
		prev_mesh = region.navigation_mesh.duplicate(true) as NavigationMesh
	var ur := get_undo_redo()
	ur.create_action("Bake Location NavigationMesh")
	ur.add_do_method(self, "_bake_nav_do", root)
	ur.add_undo_method(self, "_bake_nav_undo", root, prev_mesh, prev_rev)
	ur.commit_action()

func _bake_nav_do(root: Node3D) -> void:
	var region := root.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	if region == null:
		region = root.find_child("Navigation", true, false) as NavigationRegion3D
	if region == null:
		region = NavigationRegion3D.new()
		region.name = "NavigationRegion3D"
		region.set_script(NavScript)
		root.add_child(region)
		region.owner = root
	var bake_path := String(root.get_meta("nav_mesh_path", ""))
	if bake_path == "" and root.scene_file_path != "":
		bake_path = root.scene_file_path.get_basename() + "_nav.tres"
		root.set_meta("nav_mesh_path", bake_path)
	if region.get_script() == null:
		region.set_script(NavScript)
	region.set("bake_path", bake_path)
	# Synchronous bake (editor).
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.agent_radius = 0.4
	mesh.agent_height = 1.6
	mesh.agent_max_climb = 0.75
	var parser_settings := NavigationMeshSourceGeometryData3D.new()
	# Exclude water colliders
	for n in root.find_children("*", "CollisionObject3D", true, false):
		var nm := String(n.name).to_lower()
		if nm.contains("water") and not (n.has_meta("navigation_allow_water") and bool(n.get_meta("navigation_allow_water"))):
			n.set_meta("_nav_prev_layer", n.collision_layer)
			n.collision_layer = 0
	NavigationServer3D.parse_source_geometry_data(mesh, parser_settings, root)
	NavigationServer3D.bake_from_source_geometry_data(mesh, parser_settings)
	for n in root.find_children("*", "CollisionObject3D", true, false):
		if n.has_meta("_nav_prev_layer"):
			n.collision_layer = int(n.get_meta("_nav_prev_layer"))
			n.remove_meta("_nav_prev_layer")
	region.navigation_mesh = mesh
	if bake_path.begins_with("res://"):
		ResourceSaver.save(mesh, bake_path)
	root.set_meta("location_revision", int(root.get_meta("location_revision", 0)) + 1)
	root.set_meta("owner_edited", true)
	print("Lunex World Editor: NavMesh baked polys=", mesh.get_polygon_count(), " rev=", root.get_meta("location_revision"))

func _bake_nav_undo(root: Node3D, prev_mesh: NavigationMesh, prev_rev: int) -> void:
	var region := root.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	if region == null:
		region = root.find_child("Navigation", true, false) as NavigationRegion3D
	if region == null:
		return
	region.navigation_mesh = prev_mesh
	root.set_meta("location_revision", prev_rev)
	var bake_path := String(root.get_meta("nav_mesh_path", ""))
	if prev_mesh and bake_path.begins_with("res://"):
		ResourceSaver.save(prev_mesh, bake_path)
	print("Lunex World Editor: NavMesh undo → revision ", prev_rev)

func _on_validate() -> void:
	var root := get_edited_location_root()
	if root == null:
		push_warning("Lunex World Editor: open a Node3D location scene first.")
		return
	var report: Dictionary = VALIDATOR.validate_location(root)
	_last_issues = report.get("issues", [])
	if _issues_panel:
		_issues_panel.clear()
		if _last_issues.is_empty():
			_issues_panel.add_item("OK — no issues")
		else:
			for issue in _last_issues:
				var line := String(issue.get("code", "?")) + ": " + String(issue.get("msg", issue.get("node", "")))
				_issues_panel.add_item(line)
	print("Lunex World Editor validation: ", JSON.stringify(report))

func _on_duplicate_selected() -> void:
	## FIX-006: copy keeps type_id, mints new instance_id.
	const StableIds = preload("res://core/stable_ids.gd")
	var sel := get_editor_interface().get_selection().get_selected_nodes()
	var root := get_edited_location_root()
	if root == null or sel.is_empty():
		push_warning("Select a Node3D under the location root")
		return
	var src := sel[0] as Node3D
	if src == null:
		return
	var dup := src.duplicate() as Node3D
	dup.name = String(src.name) + "_copy"
	# Clear then assign new ids
	if dup.has_meta("instance_id"):
		dup.remove_meta("instance_id")
	if dup.has_meta("stable_id"):
		dup.remove_meta("stable_id")
	StableIds.duplicate_ids(src, dup)
	var ur := get_undo_redo()
	ur.create_action("Duplicate with new instance_id")
	ur.add_do_method(self, "_do_add_dup", root, dup)
	ur.add_undo_method(self, "_do_remove_dup", root, dup)
	ur.add_do_reference(dup)
	ur.commit_action()

func _do_add_dup(root: Node3D, n: Node3D) -> void:
	if n.get_parent() != root:
		if n.get_parent():
			n.get_parent().remove_child(n)
		root.add_child(n)
	n.owner = root
	n.position += Vector3(2, 0, 0)
	root.set_meta("owner_edited", true)

func _do_remove_dup(root: Node3D, n: Node3D) -> void:
	if n.get_parent() == root:
		root.remove_child(n)

func _on_issue_activated(index: int) -> void:
	if index < 0 or index >= _last_issues.size():
		return
	var issue: Dictionary = _last_issues[index]
	var node_path := String(issue.get("node", ""))
	if node_path.is_empty():
		return
	var root := get_edited_location_root()
	if root == null:
		return
	var n := root.get_node_or_null(NodePath(node_path.trim_prefix(str(root.get_path()) + "/")))
	if n == null and root.has_node(node_path):
		n = root.get_node(node_path)
	# Fallback: absolute from scene
	if n == null:
		n = get_tree().edited_scene_root.get_node_or_null(node_path) if get_tree().edited_scene_root else null
	if n:
		get_editor_interface().get_selection().clear()
		get_editor_interface().get_selection().add_node(n)
