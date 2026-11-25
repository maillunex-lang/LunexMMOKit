extends Node3D
## Playable Eternity Capital: 4 Darklord classes, skills from t_playerinfo/t_skill, quests, portal.
const Equipment = preload("res://actors/equipment.gd")
const DarklordMaterial = preload("res://content/shaders/darklord_material.gd")
const QuestLogScript = preload("res://content/quests/quest_log.gd")
const CombatDummyScript = preload("res://actors/combat_dummy.gd")
const HeroKitScript = preload("res://content/heroes/hero_kit.gd")
const HeroCombatScript = preload("res://actors/hero_combat.gd")

@export var actor_ids: PackedStringArray = ["10001", "20001", "30001", "40001"]
@export var class_names: PackedStringArray = ["Воин", "Лучник", "Маг", "Ассасин"]
@export var actor_glb_template := "/home/gamedev/darklord-dgi/exports/%s.glb"
@export var weapon_glb_template := "/home/gamedev/darklord-dgi/exports/weapon-%s.glb"
@export var source_root := "/home/gamedev/Darklord"
@export var material_params_path := "/home/gamedev/darklord-dgi/material-params.json"

var weapon_ids := {"10001": "100011000", "20001": "200011000", "30001": "300011000", "40001": "400011000"}
var current_index := 0
var material_params: Dictionary = {}
var hero: CharacterBody3D
var visual: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var joystick
var status_label: Label
var fps_label: Label
var quest_label: RichTextLabel
var vitals_label: Label
var interact_hint: Label
var quest_log
var hero_kit
var hero_combat
var skill_buttons: Array[Button] = []

func _ready() -> void:
	if FileAccess.file_exists(material_params_path):
		material_params = JSON.parse_string(FileAccess.get_file_as_string(material_params_path))
	if not has_node("EternityCapital"):
		var city: Node3D = load("res://world/locations/eternity_capital/eternity_capital.tscn").instantiate()
		city.name = "EternityCapital"
		add_child(city)
		move_child(city, 0)
	quest_log = QuestLogScript.new()
	quest_log.name = "QuestLog"
	add_child(quest_log)
	quest_log.load_catalog()
	quest_log.quest_updated.connect(_on_quest_ui)
	quest_log.quest_completed.connect(func(id): status_label.text = "Квест завершён: " + id)
	hero_kit = HeroKitScript.new()
	hero_kit.load_data()
	hero_combat = HeroCombatScript.new()
	hero_combat.name = "HeroCombat"
	add_child(hero_combat)
	hero_combat.hp_changed.connect(_on_vitals)
	hero_combat.mp_changed.connect(_on_vitals)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_hero()
	_spawn_shardlings()
	_build_ui()
	_load_class(0)
	_on_quest_ui("")

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
	joystick = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	layer.add_child(joystick)
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(48, -220)
	joystick.size = Vector2(160, 160)
	joystick.direction_changed.connect(func(d): if hero: hero.set_direction(d))
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	layer.add_child(status_label)
	fps_label = Label.new()
	fps_label.position = Vector2(16, 48)
	layer.add_child(fps_label)
	vitals_label = Label.new()
	vitals_label.position = Vector2(16, 72)
	layer.add_child(vitals_label)
	quest_label = RichTextLabel.new()
	quest_label.position = Vector2(16, 100)
	quest_label.size = Vector2(420, 160)
	quest_label.bbcode_enabled = true
	quest_label.fit_content = true
	layer.add_child(quest_label)
	interact_hint = Label.new()
	interact_hint.position = Vector2(400, 620)
	interact_hint.text = "E NPC  |  Space атака  |  1/2/3 умения  |  F портал"
	layer.add_child(interact_hint)
	var row := HBoxContainer.new()
	row.position = Vector2(16, 600)
	layer.add_child(row)
	for i in actor_ids.size():
		var b := Button.new()
		b.text = class_names[i]
		b.pressed.connect(_load_class.bind(i))
		row.add_child(b)
	var atk := Button.new()
	atk.text = "Атака"
	atk.pressed.connect(_try_attack)
	row.add_child(atk)
	var skills := HBoxContainer.new()
	skills.position = Vector2(16, 660)
	layer.add_child(skills)
	skill_buttons.clear()
	for s in range(3):
		var sb := Button.new()
		sb.text = "Умение %d" % (s + 1)
		sb.custom_minimum_size = Vector2(120, 40)
		sb.pressed.connect(_try_skill.bind(s))
		skills.add_child(sb)
		skill_buttons.append(sb)

func _on_quest_ui(_id: String) -> void:
	if quest_label and quest_log:
		quest_label.text = quest_log.tracker_text()

func _on_vitals(_a = 0, _b = 0) -> void:
	if vitals_label and hero_combat:
		vitals_label.text = "HP %d/%d  MP %d/%d" % [hero_combat.hp, hero_combat.max_hp, hero_combat.mp, hero_combat.max_mp]

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS %.0f" % Engine.get_frames_per_second()
	for i in skill_buttons.size():
		var left: float = hero_combat.cd_left(i) if hero_combat else 0.0
		var bar: Array = hero_kit.hotbar(String(actor_ids[current_index])) if hero_kit else []
		var label := "Умение %d" % (i + 1)
		if i < bar.size():
			label = String(bar[i].get("label", label))
		if left > 0.05:
			skill_buttons[i].text = "%s %.0f" % [label, left]
			skill_buttons[i].disabled = true
		else:
			skill_buttons[i].text = label
			skill_buttons[i].disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if hero == null:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_try_interact()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_try_portal()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_try_attack()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_1:
		_try_skill(0)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_2:
		_try_skill(1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_3:
		_try_skill(2)
	if joystick and joystick.direction != Vector2.ZERO:
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

func _try_interact() -> void:
	var npc := _nearest_with_meta("npc", 4.0)
	if npc == null:
		status_label.text = "Рядом нет NPC"
		return
	var sid := String(npc.get_meta("stable_id"))
	var started: String = quest_log.offer_from_npc(sid)
	quest_log.notify_talk(sid)
	status_label.text = ("Взят квест: " + started) if started != "" else ("Разговор: " + sid)
	_on_quest_ui("")

func _try_portal() -> void:
	var portal := _nearest_with_meta("portal", 5.0)
	if portal == null:
		status_label.text = "Рядом нет портала"
		return
	var sid := String(portal.get_meta("stable_id"))
	quest_log.notify_goto(sid)
	_on_quest_ui("")
	var scene_path := String(portal.get_meta("target_scene", ""))
	if scene_path == "" and String(portal.get_meta("target_location", "")) == "ashen_outskirts":
		scene_path = "res://world/locations/ashen_outskirts/ashen_play.tscn"
	if scene_path != "" and ResourceLoader.exists(scene_path):
		status_label.text = "Переход…"
		get_tree().change_scene_to_file(scene_path)
	else:
		status_label.text = "Портал " + sid

func _play_anim(name: String) -> void:
	if animator == null:
		return
	if animator.has_animation(name):
		animator.play(name)
	elif name.begins_with("skill") and animator.has_animation("skill001"):
		animator.play("skill001")
	elif animator.has_animation("attack"):
		animator.play("attack")

func _try_attack() -> void:
	if hero == null or hero_combat == null:
		return
	var res: Dictionary = hero_combat.try_basic(hero.global_position, hero.rotation.y, get_tree())
	if not res.get("ok", false):
		status_label.text = "Атака: " + String(res.get("reason", "?"))
		return
	_play_anim("attack")
	if res.get("hit"):
		status_label.text = "Атака %d урона" % int(res.get("damage", 0))
	else:
		status_label.text = "Промах (подойди ближе)"

func _try_skill(slot: int) -> void:
	if hero == null or hero_combat == null:
		return
	var res: Dictionary = hero_combat.try_skill(slot, hero.global_position, get_tree())
	if not res.get("ok", false):
		status_label.text = "Умение: " + String(res.get("reason", "?"))
		return
	_play_anim(String(res.get("anim", "skill001")))
	var label := String(res.get("label", "Умение"))
	if res.get("hit"):
		status_label.text = "%s — %d урона" % [label, int(res.get("damage", 0))]
	else:
		status_label.text = "%s — нет цели в радиусе" % label

func _load_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D

func _load_class(index: int) -> void:
	current_index = wrapi(index, 0, actor_ids.size())
	if visual and is_instance_valid(visual):
		visual.queue_free()
	var actor_id := String(actor_ids[current_index])
	var weapon_id := String(weapon_ids[actor_id])
	visual = _load_glb(actor_glb_template % actor_id)
	if visual == null:
		status_label.text = "нет модели " + actor_id
		return
	hero.add_child(visual)
	hero.set("visual", visual)
	if material_params.has(actor_id) and material_params[actor_id].size() > 0:
		DarklordMaterial.apply(visual, material_params[actor_id][0], source_root)
	var weapon := _load_glb(weapon_glb_template % weapon_id)
	if weapon:
		if material_params.has(weapon_id) and material_params[weapon_id].size() > 0:
			DarklordMaterial.apply(weapon, material_params[weapon_id][0], source_root)
		Equipment.equip_weapon(visual, weapon, weapon_id)
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		animator = players[0]
		hero.set("animator", animator)
		if animator.has_animation("stand"):
			animator.play("stand")
	hero_combat.setup(hero_kit, actor_id)
	var cls: Dictionary = hero_kit.class_of(actor_id)
	var src_name := String(cls.get("name_src", ""))
	status_label.text = "%s (%s) | Этернити — умения из Darklord" % [class_names[current_index], src_name]
	_on_vitals()
	# Refresh skill button labels from hotbar
	var bar: Array = hero_kit.hotbar(actor_id)
	for i in skill_buttons.size():
		if i < bar.size():
			skill_buttons[i].text = String(bar[i].get("label", "Умение"))
