extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var script: GDScript = load("res://actors/attachment_offset.gd")
	var dir := "res://content/attachments"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var specs := [
		{"kind":"weapon","equipment_id":"100011000","socket":"DM_R_Hand2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Unity identity on hand socket","secondary":""},
		{"kind":"weapon","equipment_id":"200011000","socket":"DM_R_Hand2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Unity identity on hand socket","secondary":""},
		{"kind":"weapon","equipment_id":"300011000","socket":"DM_R_Hand2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Unity identity on hand socket","secondary":""},
		{"kind":"weapon","equipment_id":"400011000","socket":"DM_R_Hand2","pos":Vector3.ZERO,"rot":Vector3(0,0,180),"scale":Vector3.ONE,"child":"body2","notes":"Unity body2 ~Z180","secondary":"DM_L_Hand2"},
		{"kind":"weapon","equipment_id":"400011000","socket":"DM_L_Hand2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3(-1,1,1),"child":"body1","notes":"Unity body1 negative X scale","secondary":"DM_R_Hand2"},
		{"kind":"wing","equipment_id":"wing_L_01","socket":"E_back2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Default wing socket","secondary":""},
		{"kind":"wing","equipment_id":"wing_L_02","socket":"E_back2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Default wing socket","secondary":""},
		{"kind":"pet","equipment_id":"XN_pet_01","socket":"","pos":Vector3(1.2,0,0),"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Beside actor pending follow","secondary":""},
		{"kind":"pet","equipment_id":"XN_pet_02","socket":"","pos":Vector3(1.2,0,0),"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Beside actor pending follow","secondary":""},
		{"kind":"mount_seat","equipment_id":"mount_001","socket":"Horse_E_back2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Rider seat default","secondary":""},
		{"kind":"mount_seat","equipment_id":"mount_002","socket":"Horse_E_back2","pos":Vector3.ZERO,"rot":Vector3.ZERO,"scale":Vector3.ONE,"child":"","notes":"Rider seat default","secondary":""},
	]
	var ok := 0
	for s in specs:
		var o: Resource = script.new()
		o.set("attachment_id", str(s.kind)+"_"+str(s.equipment_id)+(("_"+str(s.child)) if s.child!="" else ""))
		o.set("kind", s.kind)
		o.set("equipment_id", s.equipment_id)
		o.set("socket", s.socket)
		o.set("secondary_socket", s.secondary)
		o.set("position", s.pos)
		o.set("rotation_degrees", s.rot)
		o.set("scale", s.scale)
		o.set("child_name", s.child)
		o.set("notes", s.notes)
		o.set("source_unity", "CActorObject.ChangeWeapon / prefab child TRS")
		var key := str(s.kind)+"_"+str(s.equipment_id)
		if s.child != "":
			key += "_"+str(s.child)
		var path := dir.path_join(key+".tres")
		var err := ResourceSaver.save(o, path)
		print("SAVE ", path, " ", err)
		if err==OK:
			ok += 1
	print("OK ", ok, "/", specs.size())
	quit(0 if ok==specs.size() else 1)
