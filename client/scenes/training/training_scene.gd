extends Node3D
const Accessory = preload("res://actors/accessory_preview.gd")
const AttachmentEditorPanel = preload("res://ui/attachment_editor_panel.gd")
const AttachmentLibrary = preload("res://actors/attachment_library.gd")
const DarklordMaterial = preload("res://content/shaders/darklord_material.gd")
const Equipment = preload("res://actors/equipment.gd")
const VFX = preload("res://content/vfx/particle_preview.gd")
const AttackController = preload("res://combat/preview_attack.gd")
const TrainingCombat = preload("res://combat/preview_training.gd")

var actor_ids := ["10001", "20001", "30001", "40001"]
var weapon_ids := {
	"10001": "100011000",
	"20001": "200011000",
	"30001": "300011000",
	"40001": "400011000",
}
var source_root := "/home/gamedev/Darklord"
var cache_root := ""
var actor_glb_template := "/home/gamedev/darklord-dgi/exports/%s.glb"
var weapon_glb_template := "/home/gamedev/darklord-dgi/exports/weapon-%s.glb"
var material_params_path := "/home/gamedev/darklord-dgi/material-params.json"
var particle_index_path := "/home/gamedev/darklord-dgi/particle-index.json"
var attack_audio_path := "/home/gamedev/Darklord/Client/Assets/Resources/Sound/skill/FS_Atk_01.mp3"
var projectile_effect_suffix := "FS_W_attack001.prefab"
var impact_effect_suffix := "FS_hti.prefab"
var attack_clip := "attack001"
var attack_event_time := 0.5
const CLASS_EVENTS = {"10001": ["hit",0.15], "20001": ["hit",0.30], "30001": ["projectile",0.50], "40001": ["hit",0.40]}
const CLASS_FX = {"10001":"ZS_M_attack001.prefab","20001":"GJS_M_attack001.prefab","40001":"CK_W_attack001.prefab"}
const CLASS_AUDIO = {"10001":"ZS_Atk_01","20001":"SS_Atk_01","40001":"assassinatorattack01"}
var melee_visual: PackedScene
const CLASS_NAMES = ["Воин","Лучник","Маг","Ассасин"]
var speed_options := [0.5, 1.0, 1.5, 2.0]

var actor: Node3D
var weapon: Node3D
var animation_player: AnimationPlayer
var equipment_handle: Dictionary = {}
var target: Node3D
var combat: Node3D
var active_attack: Node
var material_params: Dictionary = {}
var current_actor_index := 2
var speed_index := 1
var fps_label: Label
var status_label: Label
var camera: Camera3D
var animation_select: OptionButton
var accessories: Dictionary = {}
var accessory_selectors: Dictionary = {}
const ACCESSORY_NAMES = {"wing":["wing_L_01","wing_L_02"],"pet":["XN_pet_01","XN_pet_02"],"mount":["mount_001","mount_002"]}
var accessory_root := "/home/gamedev/darklord-dgi/exports/accessories"
var orbit_angle := 0.0
var orbit_distance := 3.5
var orbit_center := Vector3(0.6,0.9,0)
var attachment_panel: VBoxContainer


func _ready() -> void:
	cache_root = OS.get_environment("LUNEX_STUDIO_CACHE")
	if cache_root.is_empty() and not OS.has_feature("android"):
		var bundled := ProjectSettings.globalize_path("res://../assets/studio")
		if FileAccess.file_exists(bundled.path_join("manifest.json")): cache_root = bundled
	if cache_root.is_empty() and OS.has_feature("android"):
		cache_root = ProjectSettings.globalize_path("user://studio-cache-v2")
	if not cache_root.is_empty():
		source_root = cache_root.path_join("source")
		actor_glb_template = cache_root.path_join("exports/%s.glb")
		weapon_glb_template = cache_root.path_join("exports/weapon-%s.glb")
		material_params_path = cache_root.path_join("material-params.json")
		particle_index_path = cache_root.path_join("particle-index.json")
		accessory_root = cache_root.path_join("exports/accessories")
		attack_audio_path = source_root.path_join("Client/Assets/Resources/Sound/skill/FS_Atk_01.mp3")
	_setup_world()
	_setup_ui()
	_load_material_params()
	_setup_combat()
	_load_actor(current_actor_index)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		orbit_angle -= event.relative.x * 0.01
		_update_camera()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: _zoom(-0.3)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom(0.3)
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			launch_attack()
		KEY_LEFT:
			_switch_actor(-1)
		KEY_RIGHT:
			_switch_actor(1)
		KEY_UP:
			_cycle_speed(1)
		KEY_DOWN:
			_cycle_speed(-1)
		KEY_R:
			reset_training()

func _setup_world() -> void:
	camera = Camera3D.new()
	camera.name = "TrainingCamera"
	add_child(camera)
	camera.position = Vector3(0.6, 1.7, 3.5)
	camera.look_at(Vector3(0.6, 0.9, 0.0))
	camera.current = true
	camera.fov = 42.0
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	add_child(light)
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	light.light_energy = 1.5
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#303746")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.75
	add_child(env)

func _process(_delta: float) -> void:
	if fps_label != null: fps_label.text = "%d FPS" % Engine.get_frames_per_second()

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TrainingUI"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	layer.add_child(panel)
	fps_label = Label.new()
	layer.add_child(fps_label)
	fps_label.position = Vector2(1100,16)
	panel.position = Vector2(16, 16)
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Loading training scene..."
	panel.add_child(status_label)
	var controls := HBoxContainer.new()
	controls.name = "Controls"
	layer.add_child(controls)
	controls.position = Vector2(16, 650)
	_add_button(controls, "◀ Класс", _switch_actor.bind(-1))
	_add_button(controls, "Атака", launch_attack)
	_add_button(controls, "Класс ▶", _switch_actor.bind(1))
	_add_button(controls, "Speed 1.0x", _cycle_speed.bind(1))
	_add_button(controls, "Сброс", reset_training)
	var studio := HBoxContainer.new()
	layer.add_child(studio)
	studio.position = Vector2(16,60)
	animation_select = OptionButton.new()
	animation_select.custom_minimum_size = Vector2(230,36)
	studio.add_child(animation_select)
	animation_select.item_selected.connect(_preview_animation)
	_add_button(studio,"Пауза / пуск",_toggle_preview)
	_add_button(studio,"Камера ◀",_orbit.bind(-0.4))
	_add_button(studio,"Камера ▶",_orbit.bind(0.4))
	_add_button(studio,"+",_zoom.bind(-0.3))
	_add_button(studio,"−",_zoom.bind(0.3))
	_add_button(studio,"Вид",_reset_camera)
	_add_button(studio,"Крепления",_toggle_attachment_editor)
	var extras := HBoxContainer.new()
	layer.add_child(extras)
	extras.position = Vector2(16,105)
	attachment_panel = AttachmentEditorPanel.new()
	attachment_panel.name = "AttachmentEditor"
	attachment_panel.visible = false
	attachment_panel.position = Vector2(920, 140)
	attachment_panel.custom_minimum_size = Vector2(340, 420)
	layer.add_child(attachment_panel)

	var fps_select := OptionButton.new()
	for limit in [30,60,90,120]: fps_select.add_item("%d FPS" % limit,limit)
	fps_select.select(1)
	Engine.max_fps = 60
	fps_select.item_selected.connect(func(i): Engine.max_fps = fps_select.get_item_id(i))
	extras.add_child(fps_select)
	for kind in ["wing","pet","mount"]:
		var selector := OptionButton.new()
		selector.custom_minimum_size = Vector2(180,44)
		selector.add_item({"wing":"Без крыльев","pet":"Без питомца","mount":"Без маунта"}[kind])
		for model_name in ACCESSORY_NAMES[kind]: selector.add_item(model_name)
		extras.add_child(selector)
		accessory_selectors[kind] = selector
		selector.item_selected.connect(_select_accessory.bind(kind))
	var help := Label.new()
	help.name = "Help"
	layer.add_child(help)
	help.position = Vector2(16, 618)
	help.visible = not OS.has_feature("android")
	help.text = "Space — attack | ←/→ — class | ↑/↓ — speed | R — reset"

func _add_button(parent: Container, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 44)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _toggle_attachment_editor() -> void:
	if attachment_panel == null:
		return
	attachment_panel.visible = not attachment_panel.visible
	if attachment_panel.visible:
		_sync_attachment_editor()

func _sync_attachment_editor() -> void:
	if attachment_panel == null or not attachment_panel.visible:
		return
	var actor_id: String = String(actor_ids[current_actor_index])
	var weapon_id: String = String(weapon_ids[actor_id])
	# Prefer editing an equipped accessory when selected; otherwise base weapon.
	for kind in ["wing", "pet", "mount"]:
		if accessories.has(kind):
			var idx: int = accessory_selectors[kind].selected
			if idx > 0:
				var equipment_id: String = ACCESSORY_NAMES[kind][idx - 1]
				var edit_kind: String = "mount_seat" if kind == "mount" else String(kind)
				attachment_panel.set_context(edit_kind, equipment_id, actor_id)
				if kind == "mount":
					attachment_panel.bind_node(actor)
				elif kind == "wing" or kind == "pet":
					attachment_panel.bind_node(accessories[kind])
				return
	attachment_panel.set_context("weapon", weapon_id, actor_id)
	if weapon != null and is_instance_valid(weapon):
		attachment_panel.bind_node(weapon)

func _setup_combat() -> void:
	combat = TrainingCombat.new()
	combat.name = "TrainingCombat"
	combat.hit_confirmed.connect(func(): _update_status("попадание"))
	add_child(combat)
	var audio := AudioStreamMP3.load_from_file(attack_audio_path)
	if audio != null:
		combat.attack_audio = audio
	else:
		_set_status("Attack audio not found; continuing silently.")

func _load_material_params() -> void:
	if not FileAccess.file_exists(material_params_path):
		material_params = {}
		_set_status("Material params not found: " + material_params_path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(material_params_path))
	if parsed is Dictionary:
		material_params = parsed
	else:
		material_params = {}
		_set_status("Material params JSON is invalid.")

func load_glb(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state)

func own_tree(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		own_tree(child, owner)

func build_effect(payload: Dictionary) -> PackedScene:
	var fx := VFX.build(payload, source_root)
	if fx == null or VFX.emitter_count(fx) == 0:
		if fx != null:
			fx.free()
		return null
	own_tree(fx, fx)
	var packed := PackedScene.new()
	if packed.pack(fx) != OK:
		fx.free()
		return null
	fx.free()
	return packed

func _load_vfx() -> void:
	combat.projectile_visual = null
	combat.impact_visual = null
	melee_visual = null
	if not FileAccess.file_exists(particle_index_path):
		_set_status("Particle index not found: " + particle_index_path)
		return
	var records: Variant = JSON.parse_string(FileAccess.get_file_as_string(particle_index_path).replace("@CACHE@",cache_root))
	if not records is Dictionary:
		_set_status("Particle index JSON is invalid.")
		return
	for key in records:
		if String(key).ends_with(projectile_effect_suffix):
			combat.projectile_visual = build_effect(records[key])
		elif String(key).ends_with(impact_effect_suffix):
			combat.impact_visual = build_effect(records[key])

func _clear_actor() -> void:
	for kind in accessories.keys(): _remove_accessory(kind)
	for selector in accessory_selectors.values(): selector.select(0)
	if combat != null:
		for child in combat.get_children(): child.queue_free()
		combat.hp = 100
	if active_attack != null and is_instance_valid(active_attack):
		active_attack.cancel()
		active_attack.queue_free()
		active_attack = null
	if not equipment_handle.is_empty() and not Equipment.unequip_weapon(equipment_handle):
		_set_status("Failed to unequip previous weapon.")
	equipment_handle = {}
	if actor != null and is_instance_valid(actor):
		actor.queue_free()
	if weapon != null and is_instance_valid(weapon):
		weapon.queue_free()
	if target != null and is_instance_valid(target):
		target.queue_free()
	actor = null
	weapon = null
	animation_player = null
	target = null

func _load_actor(index: int) -> void:
	_clear_actor()
	current_actor_index = wrapi(index, 0, actor_ids.size())
	var actor_id: String = actor_ids[current_actor_index]
	var weapon_id: String = weapon_ids.get(actor_id, "")
	actor = load_glb(actor_glb_template % actor_id)
	weapon = load_glb(weapon_glb_template % weapon_id)
	if actor == null or weapon == null:
		_set_status("Failed to load actor/weapon: " + actor_id + "/" + weapon_id)
		return
	add_child(actor)
	_apply_restored_materials(actor_id, weapon_id)
	equipment_handle = Equipment.equip_weapon(actor, weapon, weapon_id)
	if equipment_handle.is_empty():
		_set_status("Failed to equip weapon " + weapon_id)
		return
	var players := actor.find_children("*", "AnimationPlayer", true, false)
	if players.size() == 0:
		_set_status("AnimationPlayer not found for actor " + actor_id)
		return
	animation_player = players[0] as AnimationPlayer
	_refresh_animations()
	_create_target()
	if actor_id == "30001":
		projectile_effect_suffix = "FS_W_attack001.prefab"
		impact_effect_suffix = "FS_hti.prefab"
		_load_vfx()
		combat.attack_audio = AudioStreamMP3.load_from_file(attack_audio_path)
	else:
		projectile_effect_suffix = CLASS_FX[actor_id]
		impact_effect_suffix = "fx_beiji02.prefab"
		_load_vfx()
		melee_visual = combat.projectile_visual
		combat.projectile_visual = null
		var audio_base: String = source_root.path_join("Client/Assets/Resources/Sound/skill/" + CLASS_AUDIO[actor_id])
		if FileAccess.file_exists(audio_base + ".wav"):
			combat.attack_audio = AudioStreamWAV.load_from_file(audio_base + ".wav")
		else:
			combat.attack_audio = AudioStreamMP3.load_from_file(audio_base + ".mp3")
	_update_status("готов")

func _apply_restored_materials(actor_id: String, weapon_id: String) -> void:
	if material_params.is_empty():
		return
	if material_params.has(actor_id) and material_params[actor_id].size() > 0:
		DarklordMaterial.apply(actor, material_params[actor_id][0], source_root)
	if material_params.has(weapon_id) and material_params[weapon_id].size() > 0:
		DarklordMaterial.apply(weapon, material_params[weapon_id][0], source_root)

func _create_target() -> void:
	target = Accessory.load_model(cache_root.path_join("exports/training-monster.glb"))
	if target == null:
		target = MeshInstance3D.new()
		target.mesh = CapsuleMesh.new()
	target.name = "TrainingTarget"
	Accessory.idle(target)
	add_child(target)
	var marker := _attack_origin()
	target.global_position = actor.global_position + Vector3(1.2, 0.0, 0.0)
	combat.origin = marker
	combat.target = target

func _attack_origin() -> Node3D:
	for marker_name in ["E_fire", "DM_R_Hand2"]:
		var marker := actor.find_child(marker_name, true, false) as Node3D
		if marker != null:
			return marker
	return actor

func launch_attack() -> void:
	if animation_player == null:
		_set_status("Actor is not ready.")
		return
	if active_attack != null and is_instance_valid(active_attack) and active_attack.active:
		return
	if active_attack != null and is_instance_valid(active_attack):
		active_attack.queue_free()
	active_attack = AttackController.new()
	active_attack.name = "AttackController"
	add_child(active_attack)
	active_attack.projectile.connect(combat.launch)
	active_attack.impact.connect(combat.hit)
	var event: Array = CLASS_EVENTS[actor_ids[current_actor_index]]
	if not active_attack.begin(animation_player, attack_clip, [{"kind": event[0], "time": event[1]}], speed_options[speed_index]):
		_set_status("Animation clip not found: " + attack_clip)
		return
	if event[0] == "hit":
		combat.play_attack_sound()
		if melee_visual != null:
			var fx := melee_visual.instantiate() as Node3D
			actor.add_child(fx)
			get_tree().create_timer(1.5).timeout.connect(fx.queue_free)
	_update_status("attack")

func reset_training() -> void:
	if combat != null:
		combat.hp = 100
	if target != null and is_instance_valid(target):
		target.rotation.z = 0.0
	_update_status("reset")

func _switch_actor(direction: int) -> void:
	_load_actor(current_actor_index + direction)

func _cycle_speed(direction: int) -> void:
	speed_index = wrapi(speed_index + direction, 0, speed_options.size())
	var speed_button := _find_speed_button()
	if speed_button != null:
		speed_button.text = "Speed %.1fx" % speed_options[speed_index]
	_update_status("speed")

func _find_speed_button() -> Button:
	var layer := get_node_or_null("TrainingUI") as CanvasLayer
	if layer == null:
		return null
	var controls := layer.get_node_or_null("Controls") as HBoxContainer
	if controls == null:
		return null
	for child in controls.get_children():
		if child is Button and String(child.text).begins_with("Speed "):
			return child
	return null

func _update_status(reason: String) -> void:
	var actor_id: String = CLASS_NAMES[current_actor_index]
	var hp: int = int(combat.hp) if combat != null else 100
	var projectile := "yes" if combat != null and combat.projectile_visual != null else "no"
	var impact := "yes" if combat != null and combat.impact_visual != null else "no"
	_set_status("%s | Скорость %.1fx | HP %d | Снаряд %s | Эффект %s | %s" % [actor_id, speed_options[speed_index], hp, projectile, impact, reason])

func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func _refresh_animations() -> void:
	animation_select.clear()
	for clip in animation_player.get_animation_list():
		animation_select.add_item(clip)
	var idle := animation_player.get_animation_list().find("stand")
	if idle >= 0:
		animation_select.select(idle)
		_preview_animation(idle)

func _preview_animation(index: int) -> void:
	if animation_player == null or index < 0 or index >= animation_select.item_count: return
	if is_instance_valid(active_attack): active_attack.cancel()
	var clip := animation_select.get_item_text(index)
	animation_player.play(clip,-1,speed_options[speed_index])
	if accessories.has("mount"):
		var mount: Node3D = accessories["mount"]
		for player in mount.find_children("*","AnimationPlayer",true,false):
			var ride_clip := "run" if clip == "mount_run" else "stand"
			if player.has_animation(ride_clip): player.play(ride_clip,-1,speed_options[speed_index])
	_update_status(clip)

func _toggle_preview() -> void:
	if animation_player == null: return
	if is_instance_valid(active_attack) and active_attack.active: return
	if animation_player.is_playing(): animation_player.pause()
	else: animation_player.play()

func _orbit(delta: float) -> void:
	orbit_angle += delta
	_update_camera()

func _zoom(delta: float) -> void:
	orbit_distance = clampf(orbit_distance+delta,1.5,7.0)
	_update_camera()

func _reset_camera() -> void:
	orbit_angle = 0.0
	orbit_distance = 5.5 if accessories.has("mount") else 3.5
	_update_camera()

func _update_camera() -> void:
	camera.position = orbit_center + Vector3(sin(orbit_angle)*orbit_distance,0.8,cos(orbit_angle)*orbit_distance)
	camera.look_at(orbit_center)

func _toggle_accessory(kind: String) -> void:
	_select_accessory(0 if accessories.has(kind) else 1,kind)

func _select_accessory(index: int, kind: String) -> void:
	if not ACCESSORY_NAMES.has(kind) or index < 0 or index > ACCESSORY_NAMES[kind].size(): return
	_remove_accessory(kind)
	accessory_selectors[kind].select(0)
	if index == 0: return
	if actor == null: return
	var model := Accessory.load_model(accessory_root.path_join(kind+("-02" if index == 2 else "")+".glb"))
	if model == null:
		_set_status("Не найден аксессуар: "+kind)
		return
	if kind == "wing":
		var wing_id: String = ACCESSORY_NAMES["wing"][index-1]
		var wing_off = AttachmentLibrary.load_offset("wing", wing_id)
		var wing_sockets: Array = ["E_back2","E_back"]
		if wing_off != null and String(wing_off.socket) != "":
			wing_sockets = [String(wing_off.socket), "E_back2", "E_back"]
		var marker := Accessory.socket(actor, wing_sockets)
		if marker == null:
			model.free()
			return
		marker.add_child(model)
		model.transform = wing_off.to_transform() if wing_off != null else Transform3D.IDENTITY
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if "glow" in String(mesh.name).to_lower():
				if index == 2:
					var img := Image.load_from_file(accessory_root.path_join("wing-glow.png"))
					if img != null and not img.is_empty():
						var mat := StandardMaterial3D.new()
						mat.albedo_texture = ImageTexture.create_from_image(img)
						mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						mat.alpha_scissor_threshold = 0.5
						mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
						mat.cull_mode = BaseMaterial3D.CULL_DISABLED
						mesh.material_override = mat
					else: mesh.hide()
				else: mesh.hide()
	elif kind == "pet":
		var pet_id: String = ACCESSORY_NAMES["pet"][index-1]
		var pet_off = AttachmentLibrary.load_offset("pet", pet_id)
		add_child(model)
		model.transform = pet_off.to_transform() if pet_off != null else Transform3D(Basis.IDENTITY, Vector3(-0.8,0,0))
	elif kind == "mount":
		var mount_id: String = ACCESSORY_NAMES["mount"][index-1]
		var seat_off = AttachmentLibrary.load_offset("mount_seat", mount_id)
		var seat_sockets: Array = ["Horse_E_back2","Horse_E_back"]
		if seat_off != null and String(seat_off.socket) != "":
			seat_sockets = [String(seat_off.socket), "Horse_E_back2", "Horse_E_back"]
		var seat := Accessory.socket(model, seat_sockets)
		if seat == null:
			model.free()
			return
		add_child(model)
		actor.reparent(seat,false)
		actor.transform = seat_off.to_transform() if seat_off != null else Transform3D.IDENTITY
	else:
		model.free()
		return
	accessories[kind] = model
	accessory_selectors[kind].select(index)
	Accessory.idle(model)
	if kind == "mount":
		var ride := animation_player.get_animation_list().find("mount_stand")
		if ride >= 0:
			animation_select.select(ride)
			animation_player.play("mount_stand", -1.0, speed_options[speed_index])
			animation_player.advance(0.0)
		orbit_angle = 0.65
		orbit_distance = 5.5
		orbit_center.y = 1.6
		_update_camera()
	_update_status(kind)

func _remove_accessory(kind: String) -> void:
	if not accessories.has(kind): return
	var model: Node3D = accessories[kind]
	if kind == "mount" and is_instance_valid(actor):
		actor.reparent(self,false)
		actor.transform = Transform3D.IDENTITY
		_refresh_animations()
		orbit_center.y = 0.9
		_reset_camera()
	accessories.erase(kind)
	if kind == "mount": _reset_camera()
	model.queue_free()

func _exit_tree() -> void:
	VFX.clear_cache()
	if is_instance_valid(weapon) and weapon.get_parent() == null:
		weapon.free()
