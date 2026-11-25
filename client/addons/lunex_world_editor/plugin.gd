@tool
extends EditorPlugin
## WORLD-EDITOR-003 scaffold: Lunex World Editor dock + nav bake + validators.
## Full gizmo UX lands iteratively; contract is docs/WORLD_EDITOR_003.md.

const DOCK_SCENE := preload("res://addons/lunex_world_editor/library_dock.tscn")
const VALIDATOR := preload("res://addons/lunex_world_editor/location_validators.gd")

var _dock: Control

func _enter_tree() -> void:
	_dock = DOCK_SCENE.instantiate()
	_dock.plugin = self
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
	add_tool_menu_item("Lunex: Bake Location NavigationMesh", _on_bake_nav)
	add_tool_menu_item("Lunex: Validate Location", _on_validate)

func _exit_tree() -> void:
	remove_tool_menu_item("Lunex: Bake Location NavigationMesh")
	remove_tool_menu_item("Lunex: Validate Location")
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

func get_edited_location_root() -> Node3D:
	var edited := get_editor_interface().get_edited_scene_root()
	return edited as Node3D

func _on_bake_nav() -> void:
	var root := get_edited_location_root()
	if root == null:
		push_warning("Lunex World Editor: open a Node3D location scene first.")
		return
	var ur := get_undo_redo()
	ur.create_action("Bake Location NavigationMesh")
	ur.add_do_method(self, "_bake_nav_do", root)
	ur.add_undo_method(self, "_bake_nav_undo_hint")
	ur.commit_action()

func _bake_nav_do(root: Node3D) -> void:
	var region := root.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	if region == null:
		region = NavigationRegion3D.new()
		region.name = "NavigationRegion3D"
		root.add_child(region)
		region.owner = root
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.agent_radius = 0.4
	mesh.agent_height = 1.6
	region.navigation_mesh = mesh
	# Editor bake: parse from scene tree collision.
	var parser_settings := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, parser_settings, root)
	NavigationServer3D.bake_from_source_geometry_data(mesh, parser_settings)
	region.navigation_mesh = mesh
	root.set_meta("location_revision", int(root.get_meta("location_revision", 0)) + 1)
	root.set_meta("owner_edited", true)
	print("Lunex World Editor: NavMesh baked, location_revision=", root.get_meta("location_revision"))

func _bake_nav_undo_hint() -> void:
	push_warning("Lunex World Editor: re-open previous scene revision to fully undo bake (mesh resource).")

func _on_validate() -> void:
	var root := get_edited_location_root()
	if root == null:
		push_warning("Lunex World Editor: open a Node3D location scene first.")
		return
	var report: Dictionary = VALIDATOR.validate_location(root)
	print("Lunex World Editor validation: ", JSON.stringify(report))
