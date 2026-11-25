extends SceneTree
const BASE="user://dgi/" ## research archive; require LUNEX_DGI_ROOT offline copy
var meshes := {}
var materials := {}
func read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(BASE+path))
func mesh_for(row: Dictionary):
	var key: String = row.glb+":"+row.name
	if not meshes.has(key):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(BASE+"city-glb/"+row.glb,state)!=OK:return null
		var model := doc.generate_scene(state)
		for n in model.find_children("*","MeshInstance3D",true,false):
			if n.name==row.name: meshes[key]=n.mesh
		model.free()
	return meshes.get(key)
func material_for(path: String, data: Dictionary):
	if materials.has(path):return materials[path]
	var m := StandardMaterial3D.new()
	var d: Dictionary = data.get(path,{})
	var t: Dictionary = d.get("textures",{}).get("_MainTex",{})
	if t.has("file"):
		var im := Image.load_from_file(BASE+"city-materials/"+t.file)
		if im: m.albedo_texture=ImageTexture.create_from_image(im)
	var c: Dictionary = d.get("colors",{}).get("_Color",{})
	m.albedo_color=Color(c.get("r",1),c.get("g",1),c.get("b",1),c.get("a",1))
	materials[path]=m
	return m
func _initialize():
	call_deferred("run")
func run():
	var deps: Dictionary=read_json("city-dependencies.json")
	var bindings: Array=read_json("city-mesh-bindings.json")
	var mats: Dictionary=read_json("city-materials/materials.json")
	var placements: Array=read_json("city-placements.json")
	var city := Node3D.new()
	city.name="CapitalGeometryPreview"
	var count:=0
	for p in placements:
		var d: Dictionary=deps[p.asset]
		# First pass: only single-root, single-mesh prefabs with no child transforms.
		if d.transforms.size()!=1 or d.meshes.size()!=1:continue
		var b: Dictionary={}
		for r in bindings:
			if r.prefab==p.asset and r.status=="exact":b=r;break
		if b.is_empty():continue
		var mesh=mesh_for(b)
		if mesh==null:continue
		var n:=Node3D.new()
		n.name="Prefab_"+p.id
		city.add_child(n)
		n.owner=city
		n.position=Vector3(p.position[0],p.position[1],p.position[2])
		n.quaternion=Quaternion(p.rotation[0],p.rotation[1],p.rotation[2],p.rotation[3]).normalized()
		n.scale=Vector3(p.scale[0],p.scale[1],p.scale[2])
		n.set_meta("source_asset",p.asset)
		n.set_meta("source_parent",p.parent)
		var mi:=MeshInstance3D.new()
		mi.name="Geometry"
		mi.mesh=mesh
		n.add_child(mi)
		mi.owner=city
		mi.rotation.x=PI
		if d.renderers.size()==1:
			var r: Dictionary=d.renderers[0]
			mi.visible=bool(r.enabled)
			if r.materials.size()==1 and r.materials[0].assets.size()==1:
				mi.material_override=material_for(r.materials[0].assets[0],mats)
		count+=1
	var packed:=PackedScene.new()
	packed.pack(city)
	var path:= "res://world/imported/capital_geometry_preview.tscn"
	if FileAccess.file_exists(path):
		print("REFUSE_OVERWRITE")
		city.free()
		quit(1)
		return
	var err:=ResourceSaver.save(packed,path)
	print("PLACED ",count," SHARED_MESHES ",meshes.size()," MATERIALS ",materials.size()," SAVE ",err)
	city.free()
	quit(0 if err==OK and count>0 else 1)
