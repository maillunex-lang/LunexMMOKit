extends Node3D
## Playable Eternity Capital: 4 Darklord classes, skills, quests, portal.
## LOCAL PROTOTYPE until authoritative server (BETA-001 / C01). Paths via LunexAssets (FIX-002).
const Equipment = preload("res://actors/equipment.gd")
const DarklordMaterial = preload("res://content/shaders/darklord_material.gd")
const QuestLogScript = preload("res://content/quests/quest_log.gd")
const CombatDummyScript = preload("res://actors/combat_dummy.gd")
const HeroKitScript = preload("res://content/heroes/hero_kit.gd")
const HeroCombatScript = preload("res://actors/hero_combat.gd")
const SkillFxScript = preload("res://content/vfx/skill_fx.gd")
const CombatRuntimeScript = preload("res://combat/combat_runtime.gd")

@export var actor_ids: PackedStringArray = ["10001", "20001", "30001", "40001"]
@export var class_names: PackedStringArray = ["Воин", "Лучник", "Маг", "Ассасин"]

var weapon_ids := {"10001": "100011000", "20001": "200011000", "30001": "300011000", "40001": "400011000"}
var current_index := 0
var material_params: Dictionary = {}
var source_root := ""
var hero: CharacterBody3D
var visual: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var hud
var status_label: Label
var fps_label: Label
var quest_log
var hero_kit
var hero_combat
var skill_fx
var combat_runtime
var skill_buttons: Array[Button] = []

func _ready() -> void:
	LunexAssets.refresh()
	source_root = LunexAssets.source_root
	var mp := LunexAssets.material_params_path()
	if mp != "" and FileAccess.file_exists(mp):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(mp))
		if parsed is Dictionary:
			material_params = parsed
	if not has_node("EternityCapital"):
		var city_path := "res://world/locations/eternity_capital/eternity_capital.tscn"
		if not ResourceLoader.exists(city_path):
			city_path = "res://world/locations/eternity_capital/eternity_capital_generated.tscn"
		if ResourceLoader.exists(city_path):
			var city: Node3D = load(city_path).instantiate()
			city.name = "EternityCapital"
			add_child(city)
			move_child(city, 0)
	quest_log = QuestLogScript.new()
	quest_log.name = "QuestLog"
	add_child(quest_log)
	quest_log.load_catalog()
	GameSession.apply_to_quest_log(quest_log)
	quest_log.quest_updated.connect(_on_quest_ui)
	quest_log.quest_completed.connect(func(id):
		if hud: hud.set_status("Квест завершён: " + id)
		GameSession.sync_quest_log(quest_log))
	hero_kit = HeroKitScript.new()
	hero_kit.load_data()
	hero_combat = HeroCombatScript.new()
	hero_combat.name = "HeroCombat"
	add_child(hero_combat)
	hero_combat.hp_changed.connect(_on_vitals)
	hero_combat.mp_changed.connect(_on_vitals)
	skill_fx = SkillFxScript.new()
	skill_fx.name = "SkillFx"
	add_child(skill_fx)
	combat_runtime = CombatRuntimeScript.new()
	combat_runtime.name = "CombatRuntime"
	add_child(combat_runtime)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_hero()
	_spawn_shardlings()
	_build_ui()
	_ensure_nav()
	var start_idx := int(GameSession.class_index)
	_load_class(start_idx)
	_on_quest_ui("")
	if hud:
		hud.set_status("ПРОТОТИП (локально) · " + LunexAssets.status_line())

func _ensure_nav() -> void:
	var nav := NavigationRegion3D.new()
	nav.name = "Navigation"
	nav.set_script(load("res://world/location_navigation.gd"))
	add_child(nav)
	nav.set("center", Vector3(0, 0, -20))
	nav.set("half_extent", 95.0)
	nav.rebuild()

func _spawn_hero() -> void:
	hero = CharacterBody3D.new()
	hero.name = "Hero"
	hero.set_script(load("res://actors/hero_controller.gd"))
	hero.floor_snap_length = 0.6
	add_child(hero)
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	capsule.shape = shape
	capsule.position = Vector3(0, 0.9, 0)
	hero.add_child(capsule)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.set_script(load("res://world/follow_camera.gd"))
	add_child(camera)
	camera.set("target", hero)
	camera.set("follow_offset", Vector3(0, 5.5, 9))
	hero.set("camera", camera)
	var spawn := get_node_or_null("EternityCapital/PlayerSpawn") as Node3D
	hero.global_position = spawn.global_position if spawn else Vector3(0, 1, -60)
	camera.global_position = hero.global_position + Vector3(0, 5.5, 9)

func _spawn_shardlings() -> void:
	var positions := [Vector3(22, 0.05, 18), Vector3(26, 0.05, 20), Vector3(30, 0.05, 16), Vector3(24, 0.05, 24)]
	for i in positions.size():
		var mob := CharacterBody3D.new()
		mob.set_script(CombatDummyScript)
		mob.name = "Shardling_%d" % i
		mob.set("stable_id", "mob_shardling")
		mob.set("display_name", "Осколочник")
		mob.set("max_hp", 80)
		add_child(mob)
		mob.global_position = positions[i]
		mob.died.connect(func(sid): quest_log.notify_kill(sid))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	hud = load("res://ui/hud/game_hud.tscn").instantiate()
	layer.add_child(hud)

	hud.joystick_moved.connect(func(d): if hero: hero.set_direction(d))
	hud.attack_pressed.connect(_try_attack)
	hud.skill_pressed.connect(_try_skill)
	hud.interact_pressed.connect(_try_interact)
	hud.portal_pressed.connect(_try_portal)
	hud.goto_pressed.connect(_goto_quest_objective)
	hud.graphics_pressed.connect(func():
		hud.set_status("Графика: пресеты Low/Med/High/Max — в P01"))
	if hud.has_signal("inventory_pressed"):
		hud.inventory_pressed.connect(_on_inventory_pressed)
	status_label = hud.status
	fps_label = Label.new()
	fps_label.position = Vector2(16, 88)
	layer.add_child(fps_label)
	var row := HBoxContainer.new()
	row.position = Vector2(200, 16)
	layer.add_child(row)
	for i in actor_ids.size():
		var b := Button.new()
		b.text = class_names[i]
		b.pressed.connect(_load_class.bind(i))
		row.add_child(b)
	skill_buttons = [hud.btn_skill0, hud.btn_skill1, hud.btn_skill2]

func _on_quest_ui(_id: String) -> void:
	if hud and quest_log:
		hud.set_quest(quest_log.tracker_text())
	GameSession.sync_quest_log(quest_log)

func _on_vitals(_a = 0, _b = 0) -> void:
	if hud and hero_combat:
		hud.set_vitals(hero_combat.hp, hero_combat.max_hp, hero_combat.mp, hero_combat.max_mp)
		GameSession.set_vitals(hero_combat.hp, hero_combat.max_hp, hero_combat.mp, hero_combat.max_mp)

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS %.0f (Xvfb≠Android)" % Engine.get_frames_per_second()
	if hero_combat == null or hero_kit == null:
		return
	var labels := PackedStringArray()
	var bar: Array = hero_kit.hotbar(String(actor_ids[current_index]))
	for i in 3:
		var label := "Умение %d" % (i + 1)
		if i < bar.size():
			label = String(bar[i].get("label", label))
		var left: float = hero_combat.cd_left(i)
		if left > 0.05:
			labels.append("%s %.0f" % [label, left])
			if i < skill_buttons.size():
				skill_buttons[i].disabled = true
		else:
			labels.append(label)
			if i < skill_buttons.size():
				skill_buttons[i].disabled = false
	if hud:
		hud.set_skill_labels(labels)

func _unhandled_input(event: InputEvent) -> void:
	## Keyboard is optional shortcut; HUD buttons are primary (FIX-010).
	if hero == null:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E: _try_interact()
			KEY_G: _goto_quest_objective()
			KEY_F: _try_portal()
			KEY_SPACE: _try_attack()
			KEY_1: _try_skill(0)
			KEY_2: _try_skill(1)
			KEY_3: _try_skill(2)
	if hud and hud.joystick and hud.joystick.direction != Vector2.ZERO:
		return
	if event is InputEventKey:
		hero.set_direction(Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")))

func _nearest_with_meta(meta_key: String, radius: float = 3.5) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	var origin := hero.global_position
	var stack: Array = [self]
	while stack.size():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is Node3D and c.has_meta("stable_id"):
				var sid: String = String(c.get_meta("stable_id"))
				if meta_key == "any" or (meta_key == "npc" and sid.begins_with("npc_")) or (meta_key == "portal" and sid.begins_with("portal_")):
					var d: float = origin.distance_to((c as Node3D).global_position)
					if d < best_d:
						best_d = d
						best = c
	return best

func _set_status(t: String) -> void:
	if hud:
		hud.set_status(t)
	elif status_label:
		status_label.text = t

func _try_interact() -> void:
	var npc := _nearest_with_meta("npc", 4.0)
	if npc == null:
		_set_status("Рядом нет NPC")
		return
	var sid := String(npc.get_meta("stable_id"))
	var started: String = quest_log.offer_from_npc(sid)
	quest_log.notify_talk(sid)
	_set_status(("Взят квест: " + started) if started != "" else ("Разговор: " + sid))
	GameSession.sync_quest_log(quest_log)
	_on_quest_ui("")

func _try_portal() -> void:
	var portal := _nearest_with_meta("portal", 5.0)
	if portal == null:
		_set_status("Рядом нет портала")
		return
	var sid := String(portal.get_meta("stable_id"))
	quest_log.notify_goto(sid)
	_on_quest_ui("")
	var loc := String(portal.get_meta("target_location", ""))
	var scene_path := String(portal.get_meta("target_scene", ""))
	if scene_path == "" and loc == "ashen_outskirts":
		scene_path = "res://world/locations/ashen_outskirts/ashen_play.tscn"
	if scene_path == "" and loc == "shard_ruins":
		scene_path = "res://world/locations/shard_ruins/ruins_play.tscn"
	if scene_path != "" and ResourceLoader.exists(scene_path):
		_set_status("Переход…")
		GameSession.sync_quest_log(quest_log)
		GameSession.travel_to(loc if loc != "" else scene_path.get_file().get_basename())
		get_tree().change_scene_to_file(scene_path)
	else:
		_set_status("Портал " + sid)

func _play_anim(name: String) -> void:
	if animator == null:
		return
	if animator.has_animation(name):
		animator.play(name)
	elif name.begins_with("skill") and animator.has_animation("skill001"):
		animator.play("skill001")
	elif animator.has_animation("attack"):
		animator.play("attack")

func _goto_quest_objective() -> void:
	if hero == null or quest_log == null:
		return
	var sid := _active_objective_stable_id()
	if sid == "":
		_set_status("Нет активной цели — возьми квест у стража")
		return
	var target := _find_stable(sid)
	if target == null:
		_set_status("Цель %s не на этой локации" % sid)
		return
	if hero.has_method("navigate_to"):
		hero.navigate_to(target.global_position)
		_set_status("Автопуть → " + sid)

func _active_objective_stable_id() -> String:
	for qid in quest_log.active.keys():
		var prog: Dictionary = quest_log.active[qid]
		for obj in prog.objectives:
			if int(obj.have) < int(obj.need):
				return String(obj.stable_id)
	return ""

func _find_stable(stable_id: String) -> Node3D:
	var stack: Array = [self]
	while stack.size():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is Node3D and c.has_meta("stable_id") and String(c.get_meta("stable_id")) == stable_id:
				return c
	return null

func _try_attack() -> void:
	if hero == null or combat_runtime == null:
		return
	combat_runtime.actor_id = String(actor_ids[current_index])
	combat_runtime.setup(hero_combat, animator, skill_fx)
	var res: Dictionary = combat_runtime.try_basic(hero.global_position, hero.rotation.y, get_tree())
	if not res.get("ok", false):
		_set_status("Атака: " + String(res.get("reason", "?")))
		return
	_set_status("Атака %d" % int(res.get("damage", 0)) if res.get("hit") else "Промах")

func _try_skill(slot: int) -> void:
	if hero == null or combat_runtime == null:
		return
	combat_runtime.actor_id = String(actor_ids[current_index])
	combat_runtime.setup(hero_combat, animator, skill_fx)
	var res: Dictionary = combat_runtime.try_skill(slot, hero.global_position, get_tree())
	if not res.get("ok", false):
		_set_status("Умение: " + String(res.get("reason", "?")))
		return
	_set_status("%s — %d" % [String(res.get("label", "Умение")), int(res.get("damage", 0))])

func _load_glb(path: String) -> Node3D:
	if path.is_empty():
		return null
	var abs_path := path
	if path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path) and not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var load_path := path if FileAccess.file_exists(path) else abs_path
	if doc.append_from_file(load_path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D

func _load_class(index: int) -> void:
	current_index = wrapi(index, 0, actor_ids.size())
	if visual and is_instance_valid(visual):
		visual.queue_free()
	var actor_id := String(actor_ids[current_index])
	var weapon_id := String(weapon_ids[actor_id])
	visual = _load_glb(LunexAssets.actor_glb(actor_id))
	if visual == null:
		_set_status("нет модели " + actor_id + " · " + LunexAssets.status_line())
		return
	hero.add_child(visual)
	hero.set("visual", visual)
	if material_params.has(actor_id) and material_params[actor_id].size() > 0 and source_root != "":
		DarklordMaterial.apply(visual, material_params[actor_id][0], source_root)
	var weapon := _load_glb(LunexAssets.weapon_glb(weapon_id))
	if weapon:
		if material_params.has(weapon_id) and material_params[weapon_id].size() > 0 and source_root != "":
			DarklordMaterial.apply(weapon, material_params[weapon_id][0], source_root)
		Equipment.equip_weapon(visual, weapon, weapon_id)
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		animator = players[0]
		hero.set("animator", animator)
		if animator.has_animation("stand"):
			animator.play("stand")
	hero_combat.setup(hero_kit, actor_id)
	combat_runtime.setup(hero_combat, animator, skill_fx)
	combat_runtime.actor_id = actor_id
	GameSession.set_class(actor_id, current_index)
	GameSession.set_vitals(hero_combat.hp, hero_combat.max_hp, hero_combat.mp, hero_combat.max_mp)
	var cls: Dictionary = hero_kit.class_of(actor_id)
	var src_name := String(cls.get("name_src", ""))
	var skin_keys := ["zhanshi", "gongjian", "fashi", "cike"]
	if hud and hud.has_method("set_class_key"):
		hud.set_class_key(skin_keys[current_index] if current_index < skin_keys.size() else "zhanshi")
	_set_status("%s (%s) | ПРОТОТИП · Darklord skills" % [class_names[current_index], src_name])
	_on_vitals()

func _on_inventory_pressed() -> void:
	var layer := get_node_or_null("HUD")
	if layer == null:
		return
	var inv := layer.get_node_or_null("InventoryPanel")
	if inv == null:
		inv = load("res://ui/menus/inventory_panel.tscn").instantiate()
		inv.name = "InventoryPanel"
		layer.add_child(inv)
	inv.visible = true
