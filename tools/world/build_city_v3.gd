extends SceneTree
const BASE="/home/gamedev/darklord-dgi/"
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
	root.add_child(city)
	var layout: Node3D=load("res://world/imported/cs_yw_zhucheng01_layout.tscn").instantiate()
	city.add_child(layout)
	var parents: Dictionary={}
	for node in layout.find_children("*","Node3D",true,false):
		if node.has_meta("source_id"):parents[str(node.get_meta("source_id"))]=node
	var count:=0
	var parent_count:=0
	for p in placements:
		var d: Dictionary=deps[p.asset]
		if d.transforms.is_empty():continue
		var n:=Node3D.new()
		n.name="Prefab_"+p.id
		city.add_child(n)
		n.owner=city
		n.position=Vector3(p.position[0],p.position[1],p.position[2])
		n.quaternion=Quaternion(p.rotation[0],p.rotation[1],p.rotation[2],p.rotation[3]).normalized()
		n.scale=Vector3(p.scale[0],p.scale[1],p.scale[2])
		var parent_key:=str(int(p.parent))
		if parents.has(parent_key):
			n.transform=parents[parent_key].global_transform*n.transform
			parent_count+=1
		n.set_meta("source_asset",p.asset)
		n.set_meta("source_parent",p.parent)
		var nodes: Dictionary={}
		var objects: Dictionary={}
		var pending: Array=d.transforms.duplicate()
		while not pending.is_empty():
			var before:=pending.size()
			for t in pending.duplicate():
				var v: Dictionary=t.data
				var parent:=str(int(v.get("m_Father",{}).get("fileID",0)))
				if parent!="0" and not nodes.has(parent):continue
				var child: Node3D=n
				if parent!="0":
					child=Node3D.new()
					child.name="Transform_"+t.id
					nodes[parent].add_child(child)
					child.owner=city
					var pos: Dictionary=v.m_LocalPosition
					var rot: Dictionary=v.m_LocalRotation
					var sc: Dictionary=v.m_LocalScale
					child.position=Vector3(pos.x,pos.y,-pos.z)
					child.quaternion=Quaternion(-rot.x,-rot.y,rot.z,rot.w).normalized()
					child.scale=Vector3(sc.x,sc.y,sc.z)
				nodes[t.id]=child
				objects[str(int(v.m_GameObject.fileID))]=child
				pending.erase(t)
			if pending.size()==before:break
		var placed:=0
		for b in bindings:
			if b.prefab!=p.asset or b.status!="exact":continue
			var obj:=str(int(b.object.fileID))
			if not objects.has(obj):continue
			var mesh=mesh_for(b)
			if mesh==null:continue
			var mi:=MeshInstance3D.new()
			mi.name="Mesh_"+b.component
			mi.mesh=mesh
			objects[obj].add_child(mi)
			mi.owner=city
			mi.rotation.x=PI
			for r in d.renderers:
				if str(int(r.object.fileID))!=obj:continue
				mi.visible=bool(r.enabled)
				for i in range(mini(r.materials.size(),mesh.get_surface_count())):
					if r.materials[i].assets.size()==1:
						mi.set_surface_override_material(i,material_for(r.materials[i].assets[0],mats))
			placed+=1
		if placed>0:count+=1
		else:n.free()
	layout.free()
	print("PARENT_TRANSFORMS ",parent_count)
	var packed:=PackedScene.new()
	packed.pack(city)
	var path:= "res://world/imported/capital_geometry_v3.tscn"
	if FileAccess.file_exists(path):
		print("REFUSE_OVERWRITE")
		city.free()
		quit(1)
		return
	var err:=ResourceSaver.save(packed,path)
	print("PLACED ",count," SHARED_MESHES ",meshes.size()," MATERIALS ",materials.size()," SAVE ",err)
	city.free()
	quit(0 if err==OK and count>0 else 1)
