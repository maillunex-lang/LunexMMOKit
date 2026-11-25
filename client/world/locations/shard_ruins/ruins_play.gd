extends Node3D
## Shard Ruins playable wrapper. GameSession persists across portals (FIX-009).

const QuestLogScript = preload("res://content/quests/quest_log.gd")

var hero: CharacterBody3D
var camera: Camera3D
var hud
var quest_log

func _ready() -> void:
	if not has_node("ShardRuins"):
		var path := "res://world/locations/shard_ruins/shard_ruins.tscn"
		if ResourceLoader.exists(path):
			var loc: Node3D = load(path).instantiate()
			loc.name = "ShardRuins"
			add_child(loc)
			move_child(loc, 0)
	quest_log = QuestLogScript.new()
	add_child(quest_log)
	quest_log.load_catalog()
	GameSession.apply_to_quest_log(quest_log)
	GameSession.travel_to("shard_ruins")
	await get_tree().physics_frame
	_spawn_hero()
	_build_ui()
	_ensure_nav()
	if hud:
		hud.set_quest(quest_log.tracker_text())
		hud.set_status("Руины Осколка · ПРОТОТИП")

func _ensure_nav() -> void:
	var nav := NavigationRegion3D.new()
	nav.name = "Navigation"
	nav.set_script(load("res://world/location_navigation.gd"))
	add_child(nav)
	nav.set("half_extent", 45.0)
	nav.rebuild()

func _spawn_hero() -> void:
	hero = CharacterBody3D.new()
	hero.name = "Hero"
	hero.set_script(load("res://actors/hero_controller.gd"))
	add_child(hero)
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	capsule.shape = shape
	capsule.position = Vector3(0, 0.9, 0)
	hero.add_child(capsule)
	var vis := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.5
	vis.mesh = cap
	vis.position.y = 0.9
	hero.add_child(vis)
	hero.set("visual", vis)
	camera = Camera3D.new()
	camera.set_script(load("res://world/follow_camera.gd"))
	add_child(camera)
	camera.set("target", hero)
	camera.set("follow_offset", Vector3(0, 5.5, 9))
	hero.set("camera", camera)
	var spawn := get_node_or_null("ShardRuins/PlayerSpawn") as Node3D
	var default_spawn: Vector3 = spawn.global_position if spawn else Vector3(0, 1, -14)
	hero.global_position = GameSession.consume_pending_spawn() if GameSession.pending_spawn_valid else default_spawn
	GameSession.mark_safe_position("shard_ruins", hero.global_position)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = load("res://ui/hud/game_hud.tscn").instantiate()
	layer.add_child(hud)
	hud.joystick_moved.connect(func(d): if hero: hero.set_direction(d))
	hud.interact_pressed.connect(_talk_scholar)
	hud.goto_pressed.connect(func():
		var scholar := get_node_or_null("ShardRuins/ShardScholar") as Node3D
		if scholar and hero.has_method("navigate_to"):
			hero.navigate_to(scholar.global_position)
			hud.set_status("Автопуть к учёному"))
	hud.portal_pressed.connect(_to_ashen)
	var back := Button.new()
	back.text = "К Пепельному рубежу"
	back.position = Vector2(200, 16)
	back.pressed.connect(_to_ashen)
	layer.add_child(back)

func _unhandled_input(event: InputEvent) -> void:
	if hero == null:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E: _talk_scholar()
			KEY_G:
				var scholar := get_node_or_null("ShardRuins/ShardScholar") as Node3D
				if scholar and hero.has_method("navigate_to"):
					hero.navigate_to(scholar.global_position)
			KEY_F: _to_ashen()
	if hud and hud.joystick and hud.joystick.direction != Vector2.ZERO:
		return
	hero.set_direction(Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")))

func _talk_scholar() -> void:
	var scholar := get_node_or_null("ShardRuins/ShardScholar") as Node3D
	if scholar == null or hero.global_position.distance_to(scholar.global_position) > 4.0:
		hud.set_status("Подойди к Хранителю знаний")
		return
	var started: String = String(quest_log.offer_from_npc("npc_shard_scholar"))
	quest_log.notify_talk("npc_shard_scholar")
	hud.set_status(("Квест: " + started) if started != "" else "Учёный выслушал тебя")
	hud.set_quest(quest_log.tracker_text())
	GameSession.sync_quest_log(quest_log)

func _to_ashen() -> void:
	GameSession.sync_quest_log(quest_log)
	var Travel = preload("res://world/world_travel.gd")
	if hero:
		Travel.prepare_portal(GameSession, "shard_ruins", "portal_ashen_return", hero.global_position)
	else:
		GameSession.travel_to("ashen_outskirts")
	get_tree().change_scene_to_file("res://world/locations/ashen_outskirts/ashen_play.tscn")
