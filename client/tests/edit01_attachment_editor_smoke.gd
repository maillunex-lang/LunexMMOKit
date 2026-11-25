extends SceneTree
## EDIT01: Attachment editor load/save/reset round-trip via user:// overrides.

const Library = preload("res://actors/attachment_library.gd")
const PanelScript = preload("res://ui/attachment_editor_panel.gd")
const OffsetScript = preload("res://actors/attachment_offset.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var panel = PanelScript.new()
	root.add_child(panel)
	await process_frame
	# Dual hand context
	panel.set_context("weapon", "400011000", "40001", "body2")
	if panel.current == null:
		fails.append("load body2")
	elif String(panel.current.socket) != "Bip001 R Hand":
		fails.append("body2 socket " + String(panel.current.socket))
	panel._toggle_dual_child()
	if panel.child_edit.text != "body1":
		fails.append("dual toggle")
	# Override round-trip on warrior sword
	panel.set_context("weapon", "100011000", "10001", "")
	var probe := Node3D.new()
	root.add_child(probe)
	panel.bind_node(probe)
	panel.pos_x.value = 0.111
	panel.pos_y.value = -0.222
	panel.pos_z.value = 0.333
	panel.rot_y.value = 45.0
	panel.socket_mode_opt.select(0)
	panel.save_current()
	var loaded = Library.load_offset("weapon", "100011000", "10001", "")
	if loaded == null:
		fails.append("override missing")
	elif not is_equal_approx(loaded.position.x, 0.111):
		fails.append("override pos")
	# Runtime default without class still exists
	var base = Library.load_offset("weapon", "100011000")
	if base == null:
		fails.append("default missing")
	panel.reset_current()
	Library.reset_override("weapon", "100011000", "10001", "")
	# Gizmo present
	if panel.gizmo == null or not is_instance_valid(panel.gizmo):
		fails.append("gizmo")
	# Wing marker mode
	panel.set_context("wing", "wing_L_01")
	if panel.socket_mode_opt.selected != 1:
		fails.append("wing mode marker")
	if fails.is_empty():
		print("EDIT01_ATTACHMENT_EDITOR_SMOKE_OK")
		quit(0)
	else:
		for f in fails:
			print("FAIL ", f)
		print("EDIT01_ATTACHMENT_EDITOR_SMOKE_FAIL")
		quit(1)
