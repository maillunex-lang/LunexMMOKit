extends RefCounted
static func load_model(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path,state)!=OK: return null
	return doc.generate_scene(state)

static func idle(model: Node3D) -> void:
	for p in model.find_children("*","AnimationPlayer",true,false):
		for clip in ["stand","idle","stand001"]:
			if p.has_animation(clip):
				p.play(clip)
				break

static func socket(model: Node3D, names: Array) -> Node3D:
	for n in names:
		var marker := model.find_child(n,true,false) as Node3D
		if marker != null: return marker
	return null
